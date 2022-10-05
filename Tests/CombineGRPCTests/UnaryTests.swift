// Copyright 2019, ComgineGRPC
// Licensed under the Apache License, Version 2.0

import XCTest
import Combine
import GRPC
@testable import CombineGRPC

final class UnaryTests: XCTestCase {
  
  static var server: Server?
  static var client: UnaryScenariosClient?
  static var retainedCancellables: Set<AnyCancellable> = []
  
  override class func setUp() {
    super.setUp()
    server = try! makeTestServer(services: [UnaryTestsService()])
    client = makeTestClient { channel, callOptions in
      UnaryScenariosClient(channel: channel, defaultCallOptions: callOptions)
    }
  }
  
  override class func tearDown() {
    try! client?.channel.close().wait()
    try! server?.close().wait()
    retainedCancellables.removeAll()
    super.tearDown()
  }
  
  func testOk() {
    let promise = expectation(description: "Call completes successfully")
    let client = Self.client!
    let grpc = GRPCExecutor()
    
    grpc.call(client.ok)(EchoRequest.with { $0.message = "hello" })
      .sink(
        receiveCompletion: expectFinished(resolve: promise),
        receiveValue: expectValue { $0.message == "hello" }
      )
      .store(in: &Self.retainedCancellables)
    
    wait(for: [promise], timeout: 0.2)
  }

  func testFailedPrecondition() {
    let promise = expectation(description: "Call fails with failed precondition status")
    let failedPrecondition = Self.client!.failedPrecondition
    let grpc = GRPCExecutor()

    grpc.call(failedPrecondition)(EchoRequest.with { $0.message = "hello" })
      .sink(
        receiveCompletion: resolve(promise, expectingFailure: { error in
          error.status.code == .failedPrecondition && error.trailingMetadata?.first(name: "custom") == "info"
        }),
        receiveValue: expectNoValue()
      )
      .store(in: &Self.retainedCancellables)

    wait(for: [promise], timeout: 0.2)
  }

  func testNoResponse() {
    let promise = expectation(description: "Call fails with deadline exceeded status")
    let client = Self.client!
    let options = CallOptions(timeLimit: TimeLimit.timeout(.milliseconds(20)))
    let grpc = GRPCExecutor(callOptions: Just(options).eraseToAnyPublisher())
    
    grpc.call(client.noResponse)(EchoRequest.with { $0.message = "hello" })
      .sink(
        receiveCompletion: expectRPCError(code: .deadlineExceeded, resolve: promise),
        receiveValue: expectNoValue()
      )
      .store(in: &Self.retainedCancellables)
    
    wait(for: [promise], timeout: 0.2)
  }
  
  static var allTests = [
    ("Unary OK", testOk),
    ("Unary failed precondition", testFailedPrecondition),
    ("Unary no response", testNoResponse),
  ]
}
