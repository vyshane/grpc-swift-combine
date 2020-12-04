// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Foundation
import Combine
import GRPC
import NIO
import NIOHPACK
@testable import CombineGRPC

class UnaryTestsService: UnaryScenariosProvider {

  var interceptors: UnaryScenariosServerInterceptorFactoryProtocol?
  
  // OK, echoes back the message in the request
  func ok(request: EchoRequest, context: StatusOnlyCallContext) -> EventLoopFuture<EchoResponse> {
    // For large services, it is useful to be able to split each individual RPC handler out.
    // This is an example of how you might do that.
    handle(request, context, handler: self.echoHandler)
  }
  
  // Fails
  func failedPrecondition(request: EchoRequest,
                               context: StatusOnlyCallContext) -> EventLoopFuture<Empty> {
    handle(context) {
      let status = GRPCStatus(code: .failedPrecondition, message: "Failed precondition message")
      let additionalMetadata = HPACKHeaders([("custom", "info")])
      return Fail<Empty, RPCError>(error: RPCError(status: status, trailingMetadata: additionalMetadata))
        .eraseToAnyPublisher()
    }
  }
  
  // Times out
  func noResponse(request: EchoRequest, context: StatusOnlyCallContext) -> EventLoopFuture<Empty> {
    handle(context) {
      return Combine.Empty(completeImmediately: false).eraseToAnyPublisher()
    }
  }
  
  // We define a handler here but you can imagine that it might be in its own separate class.
  private func echoHandler(request: EchoRequest) -> AnyPublisher<EchoResponse, RPCError> {
    Just<EchoResponse>(EchoResponse.with { $0.message = request.message })
      .setFailureType(to: RPCError.self)
      .eraseToAnyPublisher()
  }
}
