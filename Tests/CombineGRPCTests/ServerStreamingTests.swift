// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import XCTest
import Combine
import GRPC
import NIO
@testable import CombineGRPC

class ServerStreamingTests: XCTestCase {
  
  static var serverEventLoopGroup: EventLoopGroup?
  static var client: UnaryScenariosServiceClient?
  
  override class func setUp() {
    super.setUp()
    serverEventLoopGroup = try! makeTestServer(services: [ServerStreamingTestsService()])
    client = makeTestClient { connection, callOptions in
      UnaryScenariosServiceClient(connection: connection, defaultCallOptions: callOptions)
    }
  }
  
  override class func tearDown() {
    try! client?.connection.close().wait()
    try! serverEventLoopGroup?.syncShutdownGracefully()
    super.tearDown()
  }
  
  func testServerStreamOk() {
    XCTFail("TODO")
  }
  
  func testServerStreamFailedPrecondition() {
    XCTFail("TODO")
  }
  
  func testServerStreamNoResponse() {
    XCTFail("TODO")
  }
  
  static var allTests = [
    ("Server stream OK", testServerStreamOk),
    ("Server stream failed precondition", testServerStreamFailedPrecondition),
    ("Server stream no response", testServerStreamNoResponse),
  ]
}
