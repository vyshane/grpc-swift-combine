// Copyright 2019, ComgineGRPC
// Licensed under the Apache License, Version 2.0

import Foundation
import Combine
import GRPC
import NIO
import NIOHPACK
@testable import CombineGRPC

class ClientStreamingTestsService: ClientStreamingScenariosProvider {

  var interceptors: ClientStreamingScenariosServerInterceptorFactoryProtocol?

  // OK, echoes back the last received message
  func ok(context: UnaryResponseCallContext<EchoResponse>)
    -> EventLoopFuture<(StreamEvent<EchoRequest>) -> Void>
  {
    CombineGRPC.handle(context) { requests in
      requests
        .last()
        .map { request in
          EchoResponse.with { $0.message = request.message }
        }
        .setFailureType(to: RPCError.self)
        .eraseToAnyPublisher()
    }
  }
  
  // Fails
  func failedPrecondition(context: UnaryResponseCallContext<Empty>)
    -> EventLoopFuture<(StreamEvent<EchoRequest>) -> Void>
  {
    CombineGRPC.handle(context) { _ in
      let status = GRPCStatus(code: .failedPrecondition, message: "Failed precondition message")
      let additionalMetadata = HPACKHeaders([("custom", "info")])
      return Fail<Empty, RPCError>(error: RPCError(status: status, trailingMetadata: additionalMetadata))
        .eraseToAnyPublisher()
    }
  }

  // Times out
  func noResponse(context: UnaryResponseCallContext<Empty>)
    -> EventLoopFuture<(StreamEvent<EchoRequest>) -> Void>
  {
    CombineGRPC.handle(context) { _ in
      Combine.Empty<Empty, RPCError>(completeImmediately: false).eraseToAnyPublisher()
    }
  }
}
