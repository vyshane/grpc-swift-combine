// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Foundation
import Combine
import GRPC
import SwiftProtobuf

@available(OSX 10.15, iOS 13.0, *)
public struct ClientStreamingCallPublisher<Request, Response>: Publisher where Request: Message, Response: Message {
  public typealias Output = Response
  public typealias Failure = GRPCStatus
  
  private let call: ClientStreamingCall<Request, Response>
  private let requests: AnyPublisher<Request, Error>
  
  init(clientStreamingCall: ClientStreamingCall<Request, Response>, requests: AnyPublisher<Request, Error>) {
    call = clientStreamingCall
    self.requests = requests
  }
  
  public func receive<S>(subscriber: S)
    where S : Subscriber, ClientStreamingCallPublisher.Failure == S.Failure,
    ClientStreamingCallPublisher.Output == S.Input
  {
    _ = requests.sink(
      receiveCompletion: { _ in
        _ = self.call.sendEnd()
      },
      receiveValue: {
        _ = self.call.sendMessage($0)
      }
    )
    call.response.whenSuccess { _ = subscriber.receive($0) }
    // Call status future always succeeds and signals call failure via gRPC status
    call.status.whenSuccess { sendCompletion(toSubscriber: subscriber, forStatus: $0) }
  }
}
