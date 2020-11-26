// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Foundation
import Combine
import GRPC
import NIO
import NIOHPACK
@testable import CombineGRPC

@available(OSX 10.15, iOS 13, tvOS 13, *)
class ServerStreamingTestsService: ServerStreamingScenariosProvider {

  var interceptors: ServerStreamingScenariosServerInterceptorFactoryProtocol?

  // OK, echoes back the request message three times
  func ok(request: EchoRequest, context: StreamingResponseCallContext<EchoResponse>)
    -> EventLoopFuture<GRPCStatus>
  {
    handle(context) {
      let responses = repeatElement(EchoResponse.with { $0.message = request.message}, count: 3)
      return Publishers.Sequence(sequence: responses).eraseToAnyPublisher()
    }
  }

  // Fails
  func failedPrecondition(request: EchoRequest, context: StreamingResponseCallContext<Empty>)
    -> EventLoopFuture<GRPCStatus>
  {
    handle(context) {
      let status = GRPCStatus(code: .failedPrecondition, message: "Failed precondition message")
      let additionalMetadata = HPACKHeaders([("custom", "info")])
      return Fail<Empty, RPCError>(error: RPCError(status: status, trailingMetadata: additionalMetadata))
        .eraseToAnyPublisher()
    }
  }

  // Times out
  func noResponse(request: EchoRequest, context: StreamingResponseCallContext<Empty>)
    -> EventLoopFuture<GRPCStatus>
  {
    handle(context) {
      Combine.Empty<Empty, RPCError>(completeImmediately: false).eraseToAnyPublisher()
    }
  }
}
