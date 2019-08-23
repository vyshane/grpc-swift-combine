// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import XCTest
import Combine
import GRPC
import NIO
@testable import CombineGRPC

@available(OSX 10.15, iOS 13.0, *)
final class UnaryTests: XCTestCase {
  
  static var serverEventLoopGroup: EventLoopGroup?
  static var client: UnaryScenariosServiceClient?
  static var retainedCancellables: [Cancellable] = []
  
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
    retainedCancellables.removeAll()
    super.tearDown()
  }
  
  func testUnaryOk() {
    let promise = expectation(description: "Call completes successfully")
    let client = UnaryTests.client!
    
    let cancellable = call(client.unaryOk)(EchoRequest.with { $0.message = "hello" })
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .failure(let status):
            XCTFail("Unexpected status: " + status.localizedDescription)
          case .finished:
            promise.fulfill()
          }
        },
        receiveValue: { response in
          XCTAssert(response.message == "hello")
        })
    
    UnaryTests.retainedCancellables.append(cancellable)
    wait(for: [promise], timeout: 1)
  }

  func testUnaryFailedPrecondition() {
    let promise = expectation(description: "Call fails with failed precondition status")
    let unaryFailedPrecondition = UnaryTests.client!.unaryFailedPrecondition
    
    let cancellable = call(unaryFailedPrecondition)(EchoRequest.with { $0.message = "hello" })
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .failure(let status):
            if status.code == .failedPrecondition {
              promise.fulfill()
            } else {
              XCTFail("Unexpected status: " + status.localizedDescription)
            }
          case .finished:
            XCTFail("Call should not succeed")
          }
        },
        receiveValue: { empty in
          XCTFail("Call should not return a response")
        })
    
    UnaryTests.retainedCancellables.append(cancellable)
    wait(for: [promise], timeout: 1)
  }

  func testUnaryNoResponse() {
    let promise = expectation(description: "Call fails with deadline exceeded status")
    let client = UnaryTests.client!
    let options = CallOptions(timeout: try! .milliseconds(50))
    
    // Example of partial application of call options to create a pre-configured client call.
    let callWithTimeout: ConfiguredUnaryRPC<EchoRequest, Empty> = call(options)

    let cancellable = callWithTimeout(client.unaryNoResponse)(EchoRequest.with { $0.message = "hello" })
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .failure(let status):
            if status.code == .deadlineExceeded {
              promise.fulfill()
            } else {
              XCTFail("Unexpected status: " + status.localizedDescription)
            }
          case .finished:
            XCTFail("Call should not succeed")
          }
        },
        receiveValue: { empty in
          XCTFail("Call should not return a response")
        })
    
    UnaryTests.retainedCancellables.append(cancellable)
    wait(for: [promise], timeout: 1)
  }
  
  static var allTests = [
    ("Unary OK", testUnaryOk),
    ("Unary failed precondition", testUnaryFailedPrecondition),
    ("Unary no response", testUnaryNoResponse),
  ]
}
