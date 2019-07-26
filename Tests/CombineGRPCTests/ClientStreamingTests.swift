// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import XCTest
import Combine
import GRPC
import NIO
@testable import CombineGRPC

@available(OSX 10.15, *)
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
    
    let cancellable = call(client.clientStreamOk)(requests)
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
    wait(for: [promise], timeout: 1)
  }
  
  func testClientStreamFailedPrecondition() {
    let promise = expectation(description: "Call fails with failed precondition status")
    let clientStreamFailedPrecondition = ClientStreamingTests.client!.clientStreamFailedPrecondition
    let requests = repeatElement(EchoRequest.with { $0.message = "hello"}, count: 3)
    let requestStream = Publishers.Sequence<Repeated<EchoRequest>, Error>(sequence: requests).eraseToAnyPublisher()
    
    let cancellable = call(clientStreamFailedPrecondition)(requestStream)
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
    wait(for: [promise], timeout: 1)
  }
  
  func testClientStreamNoResponse() {
    let promise = expectation(description: "Call fails with deadline exceeded status")
    let client = ClientStreamingTests.client!
    let options = CallOptions(timeout: try! .milliseconds(50))
    let requests = repeatElement(EchoRequest.with { $0.message = "hello"}, count: 3)
    let requestStream = Publishers.Sequence<Repeated<EchoRequest>, Error>(sequence: requests).eraseToAnyPublisher()
    let callWithTimeout: ConfiguredClientStreamingRPC<EchoRequest, Empty> = call(options)
    
    let cancellable = callWithTimeout(client.clientStreamNoResponse)(requestStream)
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
    wait(for: [promise], timeout: 1)
  }
  
  static var allTests = [
    ("Client stream OK", testClientStreamOk),
    ("Client stream failed precondition", testClientStreamFailedPrecondition),
    ("Client stream no response", testClientStreamNoResponse),
  ]
}
