// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import XCTest
import Combine
import GRPC
import NIO
@testable import CombineGRPC

@available(OSX 10.15, *)
final class UnaryTests: XCTestCase {
  
  static let serverEventLoopGroup = try! makeTestServer(services: [UnaryTestsService()])
  
  static let client = makeTestClient { connection, callOptions in
    UnaryScenariosServiceClient(connection: connection, defaultCallOptions: callOptions)
  }
  
  override class func tearDown() {
    try! client.connection.close().wait()
    try! serverEventLoopGroup.syncShutdownGracefully()
    super.tearDown()
  }
  
  func unaryOk() {
    let promise = expectation(description: "Response contains request message")
    
    _ = call(UnaryTests.client.unaryOk)(EchoRequest.with { $0.message = "hello" })
      .sink(receiveValue: { response in
        if response.message == "hello" {
          promise.fulfill()
        }
      })
    
    wait(for: [promise], timeout: 1)
  }

  func unaryFailedPrecondition() {
    // TODO
    XCTFail("Unimplemented test")
  }

  func unaryNoResponse() {
    // TODO
    XCTFail("Unimplemented test")
  }
  
  static var allTests = [
    ("Unary OK", unaryOk),
    ("Unary failed precondition", unaryFailedPrecondition),
    ("Unary no response", unaryNoResponse),
  ]
}
