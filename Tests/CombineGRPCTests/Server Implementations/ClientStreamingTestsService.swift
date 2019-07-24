// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Foundation
import Combine
import GRPC
import NIO
@testable import CombineGRPC

@available(OSX 10.15, *)
class ClientStreamingTestsService: ClientStreamingScenariosProvider {

  // OK, echoes back the last received message
  func clientStreamOk(context: UnaryResponseCallContext<EchoResponse>)
    -> EventLoopFuture<(StreamEvent<EchoRequest>) -> Void>
  {
    handle(context) { requests in
      requests
        .last()
        .map { request in
          EchoResponse.with { $0.message = request.message }
        }
        .mapError { _ in .processingError }
        .eraseToAnyPublisher()
    }
  }
  
  // Fails
  func clientStreamFailedPrecondition(context: UnaryResponseCallContext<Empty>)
    -> EventLoopFuture<(StreamEvent<EchoRequest>) -> Void>
  {
    handle(context) { _ in
      let status = GRPCStatus(code: .failedPrecondition, message: "Failed precondition message")
      return Fail<Empty, GRPCStatus>(error: status).eraseToAnyPublisher()
    }
  }

  // Times out
  func clientStreamNoResponse(context: UnaryResponseCallContext<Empty>)
    -> EventLoopFuture<(StreamEvent<EchoRequest>) -> Void>
  {
    handle(context) { _ in
      Combine.Empty<Empty, GRPCStatus>(completeImmediately: false).eraseToAnyPublisher()
    }
  }
}
