// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import XCTest
import Combine
import GRPC
@testable import CombineGRPC

class ClientStreamingTests: XCTestCase {
  
  static var server: Server?
  static var client: ClientStreamingScenariosClient?
  static var retainedCancellables: Set<AnyCancellable> = []
  
  override class func setUp() {
    super.setUp()
    server = try! makeTestServer(services: [ClientStreamingTestsService()])
    client = makeTestClient { channel, callOptions in
      ClientStreamingScenariosClient(channel: channel, defaultCallOptions: callOptions)
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
    let requests = Publishers.Sequence<[EchoRequest], Error>(sequence:
      [EchoRequest.with { $0.message = "hello"}, EchoRequest.with { $0.message = "world!"}]
    ).eraseToAnyPublisher()
    let grpc = GRPCExecutor()
    
    grpc.call(client.ok)(requests)
      .sink(
        receiveCompletion: expectFinished(resolve: promise),
        receiveValue: expectValue { $0.message == "world!" }
      )
      .store(in: &Self.retainedCancellables)
    
    wait(for: [promise], timeout: 0.2)
  }
  
  func testFailedPrecondition() {
    let promise = expectation(description: "Call fails with failed precondition status")
    let failedPrecondition = Self.client!.failedPrecondition
    let requests = repeatElement(EchoRequest.with { $0.message = "hello"}, count: 3)
    let requestStream = Publishers.Sequence<Repeated<EchoRequest>, Error>(sequence: requests).eraseToAnyPublisher()
    let grpc = GRPCExecutor()
    
    grpc.call(failedPrecondition)(requestStream)
      .sink(
        receiveCompletion: expectFailure(
          { error in
            error.status.code == .failedPrecondition && error.trailingMetadata?.first(name: "custom") == "info"
          },
          resolve: promise),
        receiveValue: expectNoValue()
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
    let grpc = GRPCExecutor(callOptions: Just(options).eraseToAnyPublisher())
    
    grpc.call(client.noResponse)(requestStream)
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
    let grpc = GRPCExecutor()
    
    struct ClientStreamError: Error {}
    let requests = Fail<EchoRequest, Error>(error: ClientStreamError()).eraseToAnyPublisher()
    
    grpc.call(client.ok)(requests)
      .sink(
        receiveCompletion: expectRPCError(code: .dataLoss, resolve: promise),
        receiveValue: expectNoValue()
      )
      .store(in: &Self.retainedCancellables)
    
    wait(for: [promise], timeout: 0.2)
  }
  
  static var allTests = [
    ("Client streaming OK", testOk),
    ("Client streaming failed precondition", testFailedPrecondition),
    ("Client streaming no response", testNoResponse),
    ("Client streaming with client stream error, stream cancelled", testClientStreamError),
  ]
}
