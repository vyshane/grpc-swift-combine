// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Combine
import GRPC
import NIO
import Foundation
@testable import CombineGRPC

@available(OSX 10.15, *)
class ServerStreamingTestsService: ServerStreamingScenariosProvider {

  func serverStreamOk(request: EchoRequest, context: StreamingResponseCallContext<EchoResponse>)
    -> EventLoopFuture<GRPCStatus>
  {
    return handle(context) {
      let responses = repeatElement(EchoResponse.with { $0.message = request.message}, count: 3)
      return Publishers.Sequence(sequence: responses).eraseToAnyPublisher()
    }
  }

  func serverStreamFailedPrecondition(request: EchoRequest, context: StreamingResponseCallContext<Empty>)
    -> EventLoopFuture<GRPCStatus>
  {
    return handle(context) {
      let status = GRPCStatus(code: .failedPrecondition, message: "Failed precondition message")
      return Fail<Empty, GRPCStatus>(error: status).eraseToAnyPublisher()
    }
  }

  func serverStreamNoResponse(request: EchoRequest, context: StreamingResponseCallContext<Empty>)
    -> EventLoopFuture<GRPCStatus>
  {
    return handle(context) {
      return Combine.Empty<Empty, GRPCStatus>(completeImmediately: false).eraseToAnyPublisher()
    }
  }
}
