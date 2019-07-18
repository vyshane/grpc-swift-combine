// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Combine
import GRPC
import NIO
import Foundation
@testable import CombineGRPC

@available(OSX 10.15, *)
class BidirectionalStreamingTestsService: BidirectionalStreamingScenariosProvider {
  
  func bidirectionalStreamOk(context: StreamingResponseCallContext<EchoResponse>)
    -> EventLoopFuture<(StreamEvent<EchoRequest>) -> Void>
  {
    // TODO
    return context.eventLoop.makeFailedFuture(GRPCStatus(code: .unimplemented, message: "TODO"))
  }
  
  func bidirectionalStreamFailedPrecondition(context: StreamingResponseCallContext<Empty>)
    -> EventLoopFuture<(StreamEvent<EchoRequest>) -> Void>
  {
    // TODO
    return context.eventLoop.makeFailedFuture(GRPCStatus(code: .unimplemented, message: "TODO"))
  }
  
  func bidirectionalStreamNoResponse(context: StreamingResponseCallContext<Empty>)
    -> EventLoopFuture<(StreamEvent<EchoRequest>) -> Void>
  {
    // TODO
    return context.eventLoop.makeFailedFuture(GRPCStatus(code: .unimplemented, message: "TODO"))
  }
}
