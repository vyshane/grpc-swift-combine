// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import XCTest
import Combine
import GRPC
import NIO
@testable import CombineGRPC

class ClientStreamingTests: XCTestCase {
  
  static var serverEventLoopGroup: EventLoopGroup?
  static var client: UnaryScenariosServiceClient?
  
  override class func setUp() {
    super.setUp()
    serverEventLoopGroup = try! makeTestServer(services: [UnaryTestsService()])
    client = makeTestClient { connection, callOptions in
      UnaryScenariosServiceClient(connection: connection, defaultCallOptions: callOptions)
    }
  }
  
  override class func tearDown() {
    try! client?.connection.close().wait()
    try! serverEventLoopGroup?.syncShutdownGracefully()
    super.tearDown()
  }
  
  func testClientStreamOk() {
    XCTFail("TODO")
  }
  
  func testClientStreamFailedPrecondition() {
    XCTFail("TODO")
  }
  
  func testTestClientStreamNoResponse() {
    XCTFail("TODO")
  }
  
  static var allTests = [
    ("Client stream OK", testClientStreamOk),
    ("Client stream failed precondition", testClientStreamFailedPrecondition),
    ("Client stream no response", testTestClientStreamNoResponse),
  ]
}
