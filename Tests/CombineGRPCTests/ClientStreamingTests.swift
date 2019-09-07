// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import XCTest
import Combine
import GRPC
import NIO
@testable import CombineGRPC

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
class ClientStreamingTests: XCTestCase {
  
  static var serverEventLoopGroup: EventLoopGroup?
  static var client: ClientStreamingScenariosServiceClient?
  static var retainedCancellables: [Cancellable] = []
  
  override class func setUp() {
    super.setUp()
    serverEventLoopGroup = try! makeTestServer(services: [ClientStreamingTestsService()])
    client = makeTestClient { connection, callOptions in
      ClientStreamingScenariosServiceClient(connection: connection, defaultCallOptions: callOptions)
    }
  }
  
  override class func tearDown() {
    try! client?.connection.close().wait()
    try! serverEventLoopGroup?.syncShutdownGracefully()
    retainedCancellables.removeAll()
    super.tearDown()
  }
  
  func testClientStreamOk() {
    let promise = expectation(description: "Call completes successfully")
    let client = ClientStreamingTests.client!
    let requests = Publishers.Sequence<[EchoRequest], Error>(sequence:
      [EchoRequest.with { $0.message = "hello"}, EchoRequest.with { $0.message = "world!"}]
    ).eraseToAnyPublisher()
    let grpc = GRPCExecutor()
    
    let cancellable = grpc.call(client.clientStreamOk)(requests)
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
          XCTAssert(response.message == "world!")
        }
      )
    
    ClientStreamingTests.retainedCancellables.append(cancellable)
    wait(for: [promise], timeout: 0.2)
  }
  
  func testClientStreamFailedPrecondition() {
    let promise = expectation(description: "Call fails with failed precondition status")
    let clientStreamFailedPrecondition = ClientStreamingTests.client!.clientStreamFailedPrecondition
    let requests = repeatElement(EchoRequest.with { $0.message = "hello"}, count: 3)
    let requestStream = Publishers.Sequence<Repeated<EchoRequest>, Error>(sequence: requests).eraseToAnyPublisher()
    let grpc = GRPCExecutor()
    
    let cancellable = grpc.call(clientStreamFailedPrecondition)(requestStream)
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
    
    ClientStreamingTests.retainedCancellables.append(cancellable)
    wait(for: [promise], timeout: 0.2)
  }
  
  func testClientStreamNoResponse() {
    let promise = expectation(description: "Call fails with deadline exceeded status")
    let client = ClientStreamingTests.client!
    let options = CallOptions(timeout: try! .milliseconds(50))
    let requests = repeatElement(EchoRequest.with { $0.message = "hello"}, count: 3)
    let requestStream = Publishers.Sequence<Repeated<EchoRequest>, Error>(sequence: requests).eraseToAnyPublisher()
    let grpc = GRPCExecutor(callOptions: Just(options).eraseToAnyPublisher())
    
    let cancellable = grpc.call(client.clientStreamNoResponse)(requestStream)
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
    
    ClientStreamingTests.retainedCancellables.append(cancellable)
    wait(for: [promise], timeout: 0.2)
  }
  
  static var allTests = [
    ("Client stream OK", testClientStreamOk),
    ("Client stream failed precondition", testClientStreamFailedPrecondition),
    ("Client stream no response", testClientStreamNoResponse),
  ]
}
