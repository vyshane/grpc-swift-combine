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
  static var retainedCancellables: [Cancellable] = []
  
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
    retainedCancellables.removeAll()
    super.tearDown()
  }
  
  func testBidirectionalStreamOk() {
    let promise = expectation(description: "Call completes successfully")
    let client = BidirectionalStreamingTests.client!
    let requests = repeatElement(EchoRequest.with { $0.message = "hello"}, count: 3)
    let requestStream = Publishers.Sequence<Repeated<EchoRequest>, Error>(sequence: requests).eraseToAnyPublisher()
    
    let cancellable = call(client.bidirectionalStreamOk)(requestStream)
      .filter { $0.message == "hello" }
      .count()
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .failure(let status):
            XCTFail("Unexpected status: " + status.localizedDescription)
          case .finished:
            promise.fulfill()
          }
        },
        receiveValue: { count in
          XCTAssert(count == 3)
        }
      )
    
    BidirectionalStreamingTests.retainedCancellables.append(cancellable)
    wait(for: [promise], timeout: 1)
  }
  
  // Currently crashes because of upstream bug in grpc-swift
  // See https://github.com/grpc/grpc-swift/issues/520
  func testBidirectionalStreamFailedPrecondition() {
    let promise = expectation(description: "Call fails with failed precondition status")
    let bidirectionalStreamFailedPrecondition = BidirectionalStreamingTests.client!.bidirectionalStreamFailedPrecondition
    let requests = repeatElement(EchoRequest.with { $0.message = "hello"}, count: 3)
    let requestStream = Publishers.Sequence<Repeated<EchoRequest>, Error>(sequence: requests).eraseToAnyPublisher()
    
    let cancellable = call(bidirectionalStreamFailedPrecondition)(requestStream)
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
    
    BidirectionalStreamingTests.retainedCancellables.append(cancellable)
    wait(for: [promise], timeout: 1)
  }
  
  // Currently crashes because of upstream bug in grpc-swift
  // See https://github.com/grpc/grpc-swift/issues/520
  func testBidirectionalStreamNoResponse() {
    let promise = expectation(description: "Call fails with deadline exceeded status")
    let client = BidirectionalStreamingTests.client!
    let options = CallOptions(timeout: try! .milliseconds(50))
    let requests = repeatElement(EchoRequest.with { $0.message = "hello"}, count: 3)
    let requestStream = Publishers.Sequence<Repeated<EchoRequest>, Error>(sequence: requests).eraseToAnyPublisher()
    let callWithTimeout: ConfiguredBidirectionalStreamingRPC<EchoRequest, Empty> = call(options)
    
    let cancellable = callWithTimeout(client.bidirectionalStreamNoResponse)(requestStream)
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
    
    BidirectionalStreamingTests.retainedCancellables.append(cancellable)
    wait(for: [promise], timeout: 1)
  }
  
  static var allTests = [
    ("Bidirectional stream OK", testBidirectionalStreamOk),
    ("Bidirectional stream failed precondition", testBidirectionalStreamFailedPrecondition),
    ("Bidirectional stream no response", testBidirectionalStreamNoResponse),
  ]
}
