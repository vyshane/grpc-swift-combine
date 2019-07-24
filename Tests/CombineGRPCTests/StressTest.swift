// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import XCTest
import Combine
import GRPC
import NIO
@testable import CombineGRPC

class StressTest: XCTestCase {

  static var serverEventLoopGroup: EventLoopGroup?
  static var unaryClient: UnaryScenariosServiceClient?
  static var serverStreamingClient: ServerStreamingScenariosServiceClient?
  static var clientStreamingClient: ClientStreamingScenariosServiceClient?
  static var bidirectionalStreamingClient: BidirectionalStreamingScenariosServiceClient?
  static var retainedCancellables: [Cancellable] = []
  
  override class func setUp() {
    super.setUp()

    let services: [CallHandlerProvider] = [
      UnaryTestsService(),
      ServerStreamingTestsService(),
      ClientStreamingTestsService(),
      BidirectionalStreamingTestsService()
    ]
    serverEventLoopGroup = try! makeTestServer(services: services, eventLoopGroupSize: 3)
    
    unaryClient = makeTestClient { connection, callOptions in
      UnaryScenariosServiceClient(connection: connection, defaultCallOptions: callOptions)
    }
    serverStreamingClient = makeTestClient { connection, callOptions in
      ServerStreamingScenariosServiceClient(connection: connection, defaultCallOptions: callOptions)
    }
    clientStreamingClient = makeTestClient { connection, callOptions in
      ClientStreamingScenariosServiceClient(connection: connection, defaultCallOptions: callOptions)
    }
    bidirectionalStreamingClient = makeTestClient { connection, callOptions in
      BidirectionalStreamingScenariosServiceClient(connection: connection, defaultCallOptions: callOptions)
    }
  }
  
  override class func tearDown() {
    try! unaryClient?.connection.close().wait()
    try! serverStreamingClient?.connection.close().wait()
    try! clientStreamingClient?.connection.close().wait()
    try! bidirectionalStreamingClient?.connection.close().wait()
    try! serverEventLoopGroup?.syncShutdownGracefully()
    retainedCancellables.removeAll()
    super.tearDown()
  }
  
  func testStressTest() {
    // TODO: Exercise all RPCs for a period of time
  }
  
  static var allTests = [
    ("Stress tests", testStressTest),
  ]
  
  private func randomRequest() -> EchoRequest {
    let messageOfRandomSize = (0..<100).map { _ in UUID().uuidString }.reduce("", { $0 + $1 })
    return EchoRequest.with { $0.message = messageOfRandomSize }
  }
}
