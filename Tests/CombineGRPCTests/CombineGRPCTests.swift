// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import XCTest
import Combine
import GRPC
import NIO
import Foundation
@testable import CombineGRPC

@available(OSX 10.15, *)
final class CombineGRPCTests: XCTestCase {
  
  func wip() {
    let eventLoopGroup = GRPCNIO.makeEventLoopGroup(loopCount: 1)
    let configuration = ClientConnection.Configuration(
      target: .unixDomainSocket("/tmp/grpc-swift-combine.sock"),
      eventLoopGroup: eventLoopGroup
    )
    let connection = ClientConnection(configuration: configuration)
    let client = Grpcbin_GRPCBinServiceClient(
      connection: connection, defaultCallOptions: CallOptions(timeout: try! .seconds(5))
    )
    
    // MARK: Unary
    
    _ = call(client.dummyUnary)(Grpcbin_DummyMessage()).map { response in
      return response
    }

    _ = call(client.dummyUnary)(Grpcbin_DummyMessage(), CallOptions()).map { response in
      return response
    }
    
    // MARK: Server Streaming
    
    _ = call(client.dummyServerStream)(Grpcbin_DummyMessage()).map { response in
      return response
    }
    
    _ = call(client.dummyServerStream)(Grpcbin_DummyMessage(), CallOptions()).map { response in
      return response
    }
    
    // MARK: Client Streaming
    
    let requests = AnyPublisher<Grpcbin_DummyMessage, Error>(
      Publishers.Sequence(sequence: [Grpcbin_DummyMessage(), Grpcbin_DummyMessage()])
    )
    
    _ = call(client.dummyClientStream)(requests).map { response in
      return response
    }
    
    _ = call(client.dummyClientStream)(requests, CallOptions()).map { response in
      return response
    }
  }

  static var allTests = [
    ("WIP", wip),
  ]
}
