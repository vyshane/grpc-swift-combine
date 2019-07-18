// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import XCTest
import Combine
import GRPC
import NIO
@testable import CombineGRPC

class BidirectionalStreamingTests: XCTestCase {
  
  static var serverEventLoopGroup: EventLoopGroup?
  static var client: BidirectionalStreamingScenariosServiceClient?
  
  override class func setUp() {
    super.setUp()
    serverEventLoopGroup = try! makeTestServer(services: [BidirectionalStreamingTestsService()])
    client = makeTestClient { connection, callOptions in
      BidirectionalStreamingScenariosServiceClient(connection: connection, defaultCallOptions: callOptions)
    }
  }
  
  override class func tearDown() {
    try! client?.connection.close().wait()
    try! serverEventLoopGroup?.syncShutdownGracefully()
    super.tearDown()
  }
  
  func testBidirectionalStreamOk() {
    XCTFail("TODO")
  }
  
  func testBidirectionalStreamFailedPrecondition() {
    XCTFail("TODO")
  }
  
  func testBidirectionalStreamNoResponse() {
    XCTFail("TODO")
  }
  
  static var allTests = [
    ("Bidirectional stream OK", testBidirectionalStreamOk),
    ("Bidirectional stream failed precondition", testBidirectionalStreamFailedPrecondition),
    ("Bidirectional stream no response", testBidirectionalStreamNoResponse),
  ]
}
