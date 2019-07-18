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
    // TODO
    return context.eventLoop.makeFailedFuture(GRPCStatus(code: .unimplemented, message: "TODO"))
  }

  func serverStreamFailedPrecondition(request: EchoRequest, context: StreamingResponseCallContext<Empty>)
    -> EventLoopFuture<GRPCStatus>
  {
    // TODO
    return context.eventLoop.makeFailedFuture(GRPCStatus(code: .unimplemented, message: "TODO"))
  }

  func serverStreamNoResponse(request: EchoRequest, context: StreamingResponseCallContext<Empty>)
    -> EventLoopFuture<GRPCStatus>
  {
    // TODO
    return context.eventLoop.makeFailedFuture(GRPCStatus(code: .unimplemented, message: "TODO"))
  }
}
