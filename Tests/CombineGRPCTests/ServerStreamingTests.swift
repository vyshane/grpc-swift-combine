// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import XCTest
import Combine
import GRPC
@testable import CombineGRPC

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
class ServerStreamingTests: XCTestCase {
  
  static var server: Server?
  static var client: ServerStreamingScenariosClient?
  
  // Streams will be cancelled prematurely if cancellables are deinitialized
  static var retainedCancellables: Set<AnyCancellable> = []
  
  override class func setUp() {
    super.setUp()
    server = try! makeTestServer(services: [ServerStreamingTestsService()])
    client = makeTestClient { channel, callOptions in
      ServerStreamingScenariosClient(channel: channel, defaultCallOptions: callOptions)
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
      .filter { $0.message == "hello" }
      .count()
      .sink(
        receiveCompletion: expectFinished(resolve: promise),
        receiveValue: expectValue({ count in count == 3})
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
        receiveCompletion: resolve(promise, expectingFailure:
          { error in
            error.status.code == .failedPrecondition  && error.trailingMetadata?.first(name: "custom") == "info"
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
  
  // TODO: Backpressure test
  
  
  static var allTests = [
    ("Server streaming OK", testOk),
    ("Server streaming failed precondition", testFailedPrecondition),
    ("Server streaming no response", testNoResponse),
  ]
}
