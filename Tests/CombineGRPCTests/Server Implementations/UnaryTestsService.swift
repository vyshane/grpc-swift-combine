// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Combine
import GRPC
import NIO
import Foundation
@testable import CombineGRPC

@available(OSX 10.15, *)
class UnaryTestsService: UnaryScenariosProvider {
  
  // OK, echoes back the message in the request
  func unaryOk(request: EchoRequest, context: StatusOnlyCallContext) -> EventLoopFuture<EchoResponse> {
    // For large services, it is useful to be able to split each individual RPC handler out.
    // This is an example of how you might do that.
    return handle(request, context, handler: self.echoHandler)
  }
  
  // Fails
  func unaryFailedPrecondition(request: EchoRequest,
                               context: StatusOnlyCallContext) -> EventLoopFuture<Empty> {
    return handle(context) {
      let status = GRPCStatus(code: .failedPrecondition, message: "Failed precondition message")
      return Fail<Empty, GRPCStatus>(error: status).eraseToAnyPublisher()
    }
  }
  
  // Times out
  func unaryNoResponse(request: EchoRequest, context: StatusOnlyCallContext) -> EventLoopFuture<Empty> {
    return handle(context) {
      return Combine.Empty(completeImmediately: false).eraseToAnyPublisher()
    }
  }
  
  // We define a handler here but you can imagine that it might be in its own separate class.
  private func echoHandler(request: EchoRequest) -> AnyPublisher<EchoResponse, GRPCStatus> {
    return Just<EchoResponse>(EchoResponse.with { $0.message = request.message })
      .mapError { _ in .processingError }
      .eraseToAnyPublisher()
  }
}
