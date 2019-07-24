// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Foundation
import Combine
import GRPC
import NIO
@testable import CombineGRPC

@available(OSX 10.15, *)
class ServerStreamingTestsService: ServerStreamingScenariosProvider {

  // OK, echoes back the request message three times
  func serverStreamOk(request: EchoRequest, context: StreamingResponseCallContext<EchoResponse>)
    -> EventLoopFuture<GRPCStatus>
  {
    handle(context) {
      let responses = repeatElement(EchoResponse.with { $0.message = request.message}, count: 3)
      return Publishers.Sequence(sequence: responses).eraseToAnyPublisher()
    }
  }

  // Fails
  func serverStreamFailedPrecondition(request: EchoRequest, context: StreamingResponseCallContext<Empty>)
    -> EventLoopFuture<GRPCStatus>
  {
    handle(context) {
      let status = GRPCStatus(code: .failedPrecondition, message: "Failed precondition message")
      return Fail<Empty, GRPCStatus>(error: status).eraseToAnyPublisher()
    }
  }

  // Times out
  func serverStreamNoResponse(request: EchoRequest, context: StreamingResponseCallContext<Empty>)
    -> EventLoopFuture<GRPCStatus>
  {
    handle(context) {
      Combine.Empty<Empty, GRPCStatus>(completeImmediately: false).eraseToAnyPublisher()
    }
  }
}
