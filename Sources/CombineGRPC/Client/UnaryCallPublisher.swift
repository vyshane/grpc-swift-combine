// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Foundation
import Combine
import GRPC
import SwiftProtobuf

@available(OSX 10.15, *)
public struct UnaryCallPublisher<Request, Response>: Publisher where Request: Message, Response: Message {
  public typealias Output = Response
  public typealias Failure = GRPCStatus
  
  private let call: UnaryCall<Request, Response>
  
  init(unaryCall: UnaryCall<Request, Response>) {
    call = unaryCall
  }
  
  public func receive<S>(subscriber: S)
    where S : Subscriber, UnaryCallPublisher.Failure == S.Failure, UnaryCallPublisher.Output == S.Input
  {
    call.response.whenSuccess { _ = subscriber.receive($0) }
    // Call status future always succeeds and signals call failure via gRPC status
    call.status.whenSuccess { sendCompletion(toSubscriber: subscriber, forStatus: $0) }
  }
}
