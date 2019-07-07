// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Foundation
import Combine
import GRPC
import SwiftProtobuf

@available(OSX 10.15, *)
public struct BidirectionalStreamingCallPublisher<Request, Response>: Publisher
  where Request: Message, Response: Message
{
  public typealias Output = Response
  public typealias Failure = StatusError
  
  let call: BidirectionalStreamingCall<Request, Response>
  let bridge: MessageBridge<Response>
  let requests: AnyPublisher<Request, Error>
  
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
    _ = requests.map { self.call.sendMessage($0) }
    _ = bridge.messages.map(subscriber.receive)
    call.status.whenSuccess { sendCompletion(toSubscriber: subscriber, forStatus: $0) }
  }
}
