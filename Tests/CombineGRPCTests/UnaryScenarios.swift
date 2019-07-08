// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import GRPC
import NIO
import Foundation

class UnaryScenarios: UnaryScenariosProvider {
  
  func unaryOk(request: Request, context: StatusOnlyCallContext) -> EventLoopFuture<Response> {
    return context.eventLoop.makeSucceededFuture(
      Response.with { $0.uuid = UUID().uuidString }
    )
  }
  
  func unaryFailedPrecondition(request: Request, context: StatusOnlyCallContext) -> EventLoopFuture<Empty> {
    // TODO: Check how errors should be sent to client
    let error = GRPCStatus.init(code: .failedPrecondition, message: "Failed Precondition")
    context.responseStatus = error
    return context.eventLoop.makeFailedFuture(error)
  }
  
  func unaryNoResponse(request: Request, context: StatusOnlyCallContext) -> EventLoopFuture<Empty> {
    sleep(60)
    return context.eventLoop.makeSucceededFuture(Empty())
  }
}
