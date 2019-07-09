// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Combine
import GRPC
import NIO
import SwiftProtobuf

// MARK: Unary

public typealias UnaryHandler<Request, Response> =
  (Request) -> AnyPublisher<Response, StatusError>

public func handle<Request, Response>(_ request: Request, _ context: StatusOnlyCallContext)
  -> (@escaping UnaryHandler<Request, Response>)
  -> EventLoopFuture<Response>
{
  return { handler in
    var future: EventLoopFuture<Response>?
    _ = handler(request).sink(
      receiveCompletion: { completion in
        switch completion {
        case .failure(let error):
          context.responseStatus = GRPCStatus(code: error.code, message: error.message)
          future = context.eventLoop.makeFailedFuture(error)
        case .finished:
          context.responseStatus = GRPCStatus(
            code: .aborted,
            message: "Response publisher completed without sending a value"
          )
          future = context.eventLoop.makeFailedFuture(StatusError(code: .aborted))
        }
      },
      receiveValue: { response in
        future = context.eventLoop.makeSucceededFuture(response)
      }
    )
    return future!
  }
}
