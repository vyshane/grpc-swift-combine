// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Combine
import GRPC
import NIO
import Foundation
@testable import CombineGRPC

class UnaryScenarios: UnaryScenariosProvider {
  
  func unaryOk(request: Request, context: StatusOnlyCallContext) -> EventLoopFuture<Response> {
    return handle(request, context) { request in
      return Publishers.Once(
        Response.with { $0.uuid = UUID().uuidString }
      ).eraseToAnyPublisher()
    }
  }
  
  func unaryFailedPrecondition(request: Request, context: StatusOnlyCallContext) -> EventLoopFuture<Empty> {
    // TODO: Check how errors should be sent to client
    let error = GRPCStatus(code: .failedPrecondition, message: "Failed Precondition")
    context.responseStatus = error
    return context.eventLoop.makeFailedFuture(error)
  }
  
  func unaryNoResponse(request: Request, context: StatusOnlyCallContext) -> EventLoopFuture<Empty> {
    sleep(60)
    return context.eventLoop.makeSucceededFuture(Empty())
  }
}
