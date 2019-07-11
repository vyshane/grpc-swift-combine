// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Combine
import GRPC
import NIO
import SwiftProtobuf

// MARK: Unary

@available(OSX 10.15, *)
public func handle<Response>(_ context: StatusOnlyCallContext,
                             handler: () -> AnyPublisher<Response, GRPCStatus>) -> EventLoopFuture<Response>
{
  // TODO: Abstract out shared implementation
  var future: EventLoopFuture<Response>?
  _ = handler().sink(
    receiveCompletion: { completion in
      switch completion {
      case .failure(let status):
        future = context.eventLoop.makeFailedFuture(status)
      case .finished:
        let status = GRPCStatus(code: .aborted,
                                message: "Response publisher completed without sending a value")
        future = context.eventLoop.makeFailedFuture(status)
      }
    },
    receiveValue: { response in
      // First value received will complete the call
      future = context.eventLoop.makeSucceededFuture(response)
    }
  )
  return future!
}

@available(OSX 10.15, *)
public func handle<Request, Response>(_ request: Request, _ context: StatusOnlyCallContext,
                                      handler: (Request) -> AnyPublisher<Response, GRPCStatus>)
                                     -> EventLoopFuture<Response>
{
  // TODO: Abstract out shared implementation
  var future: EventLoopFuture<Response>?
  _ = handler(request).sink(
    receiveCompletion: { completion in
      switch completion {
      case .failure(let status):
        future = context.eventLoop.makeFailedFuture(status)
      case .finished:
        let status = GRPCStatus(code: .aborted,
                                message: "Response publisher completed without sending a value")
        future = context.eventLoop.makeFailedFuture(status)
      }
    },
    receiveValue: { response in
      // First value received will complete the call
      future = context.eventLoop.makeSucceededFuture(response)
    }
  )
  return future!
}
