// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Foundation
import Combine
import GRPC
import SwiftProtobuf

@available(OSX 10.15, iOS 13.0, *)
public struct BidirectionalStreamingCallPublisher<Request, Response>: Publisher
  where Request: Message, Response: Message
{
  public typealias Output = Response
  public typealias Failure = GRPCStatus
  
  private let call: BidirectionalStreamingCall<Request, Response>
  private let bridge: MessageBridge<Response>
  private let requests: AnyPublisher<Request, Error>
  
  init(bidirectionalStreamingCall: BidirectionalStreamingCall<Request, Response>,
       messageBridge: MessageBridge<Response>,
       requests: AnyPublisher<Request, Error>) {
    call = bidirectionalStreamingCall
    bridge = messageBridge
    self.requests = requests
  }
  
  public func receive<S>(subscriber: S)
    where S : Subscriber, BidirectionalStreamingCallPublisher.Failure == S.Failure,
    BidirectionalStreamingCallPublisher.Output == S.Input
  {
    _ = requests.sink(
      receiveCompletion: { _ in
        _ = self.call.sendEnd()
      },
      receiveValue: {
        _ = self.call.sendMessage($0)
      }
    )
    bridge.messagePublisher.subscribe(subscriber)
    // Call status future always succeeds and signals call failure via gRPC status
    call.status.whenSuccess { sendCompletion(toSubscriber: subscriber, forStatus: $0) }
  }
}
