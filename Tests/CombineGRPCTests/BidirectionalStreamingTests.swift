// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import XCTest
import Combine
import GRPC
import NIOHPACK
@testable import CombineGRPC

class BidirectionalStreamingTests: XCTestCase {
  
  static var server: Server?
  static var client: BidirectionalStreamingScenariosClient?
  static var retainedCancellables: Set<AnyCancellable> = []
  
  override class func setUp() {
    super.setUp()
    server = try! makeTestServer(services: [BidirectionalStreamingTestsService()])
    client = makeTestClient { channel, callOptions in
      BidirectionalStreamingScenariosClient(channel: channel, defaultCallOptions: callOptions)
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
    let requests = repeatElement(EchoRequest.with { $0.message = "hello"}, count: 3)
    let requestStream = Publishers.Sequence<Repeated<EchoRequest>, Error>(sequence: requests).eraseToAnyPublisher()

    GRPCExecutor()
      .call(client.ok)(requestStream)
      .filter { $0.message == "hello" }
      .count()
      .sink(
        receiveCompletion: expectFinished(resolve: promise),
        receiveValue: expectValue { count in count == 3 }
      )
      .store(in: &Self.retainedCancellables)
    
    wait(for: [promise], timeout: 0.2)
  }
  
  func testFailedPrecondition() {
    let promise = expectation(description: "Call fails with failed precondition status")
    let failedPrecondition = Self.client!.failedPrecondition
    let requests = repeatElement(EchoRequest.with { $0.message = "hello"}, count: 3)
    let requestStream = Publishers.Sequence<Repeated<EchoRequest>, Error>(sequence: requests).eraseToAnyPublisher()

    GRPCExecutor()
      .call(failedPrecondition)(requestStream)
      .sink(
        receiveCompletion: resolve(promise, expectingFailure:
          { error in
            error.status.code == .failedPrecondition && error.trailingMetadata?.first(name: "custom") == "info"
          }),
        receiveValue: { empty in
          XCTFail("Call should not return a response")
        }
      )
      .store(in: &Self.retainedCancellables)
    
    wait(for: [promise], timeout: 0.2)
  }
  
  func testNoResponse() {
    let promise = expectation(description: "Call fails with deadline exceeded status")
    let client = Self.client!
    let options = CallOptions(timeLimit: TimeLimit.timeout(.milliseconds(20)))
    let requests = repeatElement(EchoRequest.with { $0.message = "hello"}, count: 3)
    let requestStream = Publishers.Sequence<Repeated<EchoRequest>, Error>(sequence: requests).eraseToAnyPublisher()
    
    GRPCExecutor(callOptions: Just(options).eraseToAnyPublisher())
      .call(client.noResponse)(requestStream)
      .sink(
        receiveCompletion: expectRPCError(code: .deadlineExceeded, resolve: promise),
        receiveValue: expectNoValue()
      )
      .store(in: &Self.retainedCancellables)
    
    wait(for: [promise], timeout: 0.2)
  }
  
  func testClientStreamError() {
    let promise = expectation(description: "Call fails with cancelled status")
    let client = Self.client!

    struct ClientStreamError: Error {}
    let requests = Fail<EchoRequest, Error>(error: ClientStreamError()).eraseToAnyPublisher()
    
    GRPCExecutor()
      .call(client.ok)(requests)
      .sink(
        receiveCompletion: expectRPCError(code: .dataLoss, resolve: promise),
        receiveValue: expectNoValue()
      )
      .store(in: &Self.retainedCancellables)
    
    wait(for: [promise], timeout: 0.2)
  }
  
  static var allTests = [
    ("Bidirectional streaming OK", testOk),
    ("Bidirectional streaming failed precondition", testFailedPrecondition),
    ("Bidirectional streaming no response", testNoResponse),
    ("Bidirectional streaming with client stream error, stream cancelled", testClientStreamError),
  ]
}
