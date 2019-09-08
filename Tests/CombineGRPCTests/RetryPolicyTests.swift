// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import XCTest
import Combine
import GRPC
import NIO
@testable import CombineGRPC

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
final class RetryPolicyTests: XCTestCase {
  
  static var serverEventLoopGroup: EventLoopGroup?
  static var client: RetryScenariosServiceClient?
  static var retainedCancellables: [Cancellable] = []
  
  override class func setUp() {
    super.setUp()
    serverEventLoopGroup = try! makeTestServer(services: [RetryPolicyTestsService()])
    client = makeTestClient { connection, callOptions in
      RetryScenariosServiceClient(connection: connection, defaultCallOptions: callOptions)
    }
  }
  
  override class func tearDown() {
    try! client?.connection.close().wait()
    try! serverEventLoopGroup?.syncShutdownGracefully()
    retainedCancellables.removeAll()
    super.tearDown()
  }
  
  func testRetriesNotExceeded() {
    let promise = expectation(description: "Call completes successfully after retrying twice")
    let client = RetryPolicyTests.client!
    let grpc = GRPCExecutor(retry: .failedCall(upTo: 2, when: { $0.code == .failedPrecondition }))

    let request = FailThenSucceedRequest.with {
      $0.key = "testRetriesNotExceeded"
      $0.numFailures = 2
    }
    
    let cancellable = grpc.call(client.failThenSucceed)(request)
      .sink(
        receiveCompletion: { switch $0 {
          case .failure(let status):
            XCTFail("Unexpected status: " + status.localizedDescription)
          case .finished:
            promise.fulfill()
        }},
        receiveValue: { response in
          XCTAssert(Int(response.numFailures) == 2)
        })
    
    RetryPolicyTests.retainedCancellables.append(cancellable)
    wait(for: [promise], timeout: 0.2)
  }
  
  func testRetriesExceededGaveUp() {
    let callPromise = expectation(description: "Call fails after exceeding max number of retries")
    let onGiveUpPromise = expectation(description: "On give up callback called")
    
    let client = RetryPolicyTests.client!
    let grpc = GRPCExecutor(retry:
      .failedCall(upTo: 2, when: { $0.code == .failedPrecondition }, onGiveUp: { onGiveUpPromise.fulfill() })
    )

    let request = FailThenSucceedRequest.with {
      $0.key = "testRetriesExceededGaveUp"
      $0.numFailures = 3
    }
    
    let cancellable = grpc.call(client.failThenSucceed)(request)
      .sink(
        receiveCompletion: { switch $0 {
          case .failure(let status):
            if status.code == .failedPrecondition {
              callPromise.fulfill()
            }
          case .finished:
            XCTFail("Call should fail, but was completed")
        }},
        receiveValue: { response in
          XCTFail("Call should fail, but got response: " + response.debugDescription)
        })
    
    RetryPolicyTests.retainedCancellables.append(cancellable)
    wait(for: [callPromise, onGiveUpPromise], timeout: 0.2)
  }
  
  func testRetryStatusDoesNotMatch() {
    let promise = expectation(description: "Call fails when retry status does not match")
    let client = RetryPolicyTests.client!
    let grpc = GRPCExecutor(retry: .failedCall(upTo: 2, when: { $0.code == .notFound }))

    let request = FailThenSucceedRequest.with {
      $0.key = "testRetryStatusDoesNotMatch"
      $0.numFailures = 1
    }
    
    let cancellable = grpc.call(client.failThenSucceed)(request)
      .sink(
        receiveCompletion: { switch $0 {
          case .failure(let status):
            if status.code == .failedPrecondition {
              promise.fulfill()
            }
          case .finished:
            XCTFail("Call should fail, but was completed")
        }},
        receiveValue: { response in
          XCTFail("Call should fail, but got response: " + response.debugDescription)
        })
    
    RetryPolicyTests.retainedCancellables.append(cancellable)
    wait(for: [promise], timeout: 0.2)
  }
  
  static var allTests = [
    ("Number of retries not exceeded", testRetriesNotExceeded),
    ("Number of retries exceeded, gave up", testRetriesExceededGaveUp),
    ("Retry status does not match", testRetryStatusDoesNotMatch),
  ]
}
