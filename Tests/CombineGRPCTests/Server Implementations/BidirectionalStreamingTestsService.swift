// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Foundation
import Combine
import GRPC
import NIO
@testable import CombineGRPC

@available(OSX 10.15, *)
class BidirectionalStreamingTestsService: BidirectionalStreamingScenariosProvider {
  
  // OK, echoes back each request message
  func bidirectionalStreamOk(context: StreamingResponseCallContext<EchoResponse>)
    -> EventLoopFuture<(StreamEvent<EchoRequest>) -> Void>
  {
    return handle(context) { requests in
      requests
        .map { request in
          EchoResponse.with { $0.message = request.message }
        }
        .mapError { _ in .processingError }
        .eraseToAnyPublisher()
    }
  }
  
  // Fails
  func bidirectionalStreamFailedPrecondition(context: StreamingResponseCallContext<Empty>)
    -> EventLoopFuture<(StreamEvent<EchoRequest>) -> Void>
  {
    return handle(context) { _ in
      let status = GRPCStatus(code: .failedPrecondition, message: "Failed precondition message")
      return Fail<Empty, GRPCStatus>(error: status).eraseToAnyPublisher()
    }
  }
  
  // Times out
  func bidirectionalStreamNoResponse(context: StreamingResponseCallContext<Empty>)
    -> EventLoopFuture<(StreamEvent<EchoRequest>) -> Void>
  {
    return handle(context) { _ in
      return Combine.Empty<Empty, GRPCStatus>(completeImmediately: false).eraseToAnyPublisher()
    }
  }
}
