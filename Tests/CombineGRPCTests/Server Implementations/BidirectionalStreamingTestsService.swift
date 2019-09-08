// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Foundation
import Combine
import GRPC
import NIO
@testable import CombineGRPC

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
class BidirectionalStreamingTestsService: BidirectionalStreamingScenariosProvider {
  
  // OK, echoes back each message in the request stream
  func bidirectionalStreamOk(context: StreamingResponseCallContext<EchoResponse>)
    -> EventLoopFuture<(StreamEvent<EchoRequest>) -> Void>
  {
    handle(context) { requests in
      requests
        .map { req in
          EchoResponse.with { $0.message = req.message }
        }
        .setFailureType(to: GRPCStatus.self)
        .eraseToAnyPublisher()
    }
  }
  
  // Fails
  func bidirectionalStreamFailedPrecondition(context: StreamingResponseCallContext<Empty>)
    -> EventLoopFuture<(StreamEvent<EchoRequest>) -> Void>
  {
    handle(context) { _ in
      let status = GRPCStatus(code: .failedPrecondition, message: "Failed precondition message")
      return Fail<Empty, GRPCStatus>(error: status).eraseToAnyPublisher()
    }
  }
  
  // Times out
  func bidirectionalStreamNoResponse(context: StreamingResponseCallContext<Empty>)
    -> EventLoopFuture<(StreamEvent<EchoRequest>) -> Void>
  {
    handle(context) { _ in
      Combine.Empty<Empty, GRPCStatus>(completeImmediately: false).eraseToAnyPublisher()
    }
  }
}
