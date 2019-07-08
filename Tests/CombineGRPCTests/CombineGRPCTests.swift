// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import XCTest
import Combine
import GRPC
import NIO
import Foundation
@testable import CombineGRPC

final class CombineGRPCTests: XCTestCase {
  
  func wip() {
    let eventLoopGroup = GRPCNIO.makeEventLoopGroup(loopCount: 1)
    let configuration = ClientConnection.Configuration(
      target: .unixDomainSocket("/tmp/grpc-swift-combine.sock"),
      eventLoopGroup: eventLoopGroup
    )
    let connection = ClientConnection(configuration: configuration)
    let client = UnaryScenariosServiceClient(
      connection: connection, defaultCallOptions: CallOptions(timeout: try! .seconds(5))
    )
    
    _ = call(client.unaryOk)(Request())
      .sink(receiveCompletion: { print ($0) }, receiveValue: { print ($0) })

    _ = call(client.unaryOk)(Request(), CallOptions())
      .sink(receiveCompletion: { print ($0) }, receiveValue: { print ($0) })
  }

  static var allTests = [
    ("WIP", wip),
  ]
}
