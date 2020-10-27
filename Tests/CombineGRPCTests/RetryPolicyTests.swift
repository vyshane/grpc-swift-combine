// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import XCTest
import Combine
import GRPC
import NIOHPACK
@testable import CombineGRPC

@available(OSX 10.15, iOS 13, tvOS 13, *)
final class RetryPolicyTests: XCTestCase {
  
  static var server: Server?
  static var client: RetryScenariosClient?
  static var retainedCancellables: Set<AnyCancellable> = []
  
  override class func setUp() {
    super.setUp()
    server = try! makeTestServer(services: [RetryPolicyTestsService()])
    client = makeTestClient { channel, callOptions in
      RetryScenariosClient(channel: channel, defaultCallOptions: callOptions)
    }
  }
  
  override class func tearDown() {
    try! client?.channel.close().wait()
    try! server?.close().wait()
    retainedCancellables.removeAll()
    super.tearDown()
  }
  
  func testRetriesNotExceeded() {
    let promise = expectation(description: "Call completes successfully after retrying twice")
    let client = Self.client!
    
    let grpc = GRPCExecutor(retry: .failedCall(
      upTo: 2,
      when: { $0.status.code == .failedPrecondition },
      didGiveUp: { XCTFail("onGiveUp callback should not trigger") }
    ))

    let request = FailThenSucceedRequest.with {
      $0.key = "testRetriesNotExceeded"
      $0.numFailures = 2
    }
    
    grpc.call(client.failThenSucceed)(request)
      .sink(
        receiveCompletion: { switch $0 {
          case .failure(let status):
            XCTFail("Unexpected status: " + status.localizedDescription)
          case .finished:
            promise.fulfill()
        }},
        receiveValue: { response in
          XCTAssert(Int(response.numFailures) == 2)
        }
      )
      .store(in: &Self.retainedCancellables)
    
    wait(for: [promise], timeout: 0.2)
  }
  
  func testRetriesExceededGaveUp() {
    let callPromise = expectation(description: "Call fails after exceeding max number of retries")
    let onGiveUpPromise = expectation(description: "On give up callback called")
    
    let client = Self.client!
    let grpc = GRPCExecutor(retry:
      .failedCall(upTo: 2, when: { $0.status.code == .failedPrecondition }, didGiveUp: { onGiveUpPromise.fulfill() })
    )

    let request = FailThenSucceedRequest.with {
      $0.key = "testRetriesExceededGaveUp"
      $0.numFailures = 3
    }
    
    grpc.call(client.failThenSucceed)(request)
      .sink(
        receiveCompletion: { switch $0 {
          case .failure(let error):
            if error.status.code == .failedPrecondition {
              callPromise.fulfill()
            }
          case .finished:
            XCTFail("Call should fail, but was completed")
        }},
        receiveValue: { response in
          XCTFail("Call should fail, but got response: " + response.debugDescription)
        }
      )
      .store(in: &Self.retainedCancellables)
    
    wait(for: [callPromise, onGiveUpPromise], timeout: 0.2)
  }
  
  func testRetryStatusDoesNotMatch() {
    let promise = expectation(description: "Call fails when retry status does not match")
    let client = Self.client!
    let grpc = GRPCExecutor(retry: .failedCall(upTo: 2, when: { $0.status.code == .notFound }))

    let request = FailThenSucceedRequest.with {
      $0.key = "testRetryStatusDoesNotMatch"
      $0.numFailures = 1
    }
    
    grpc.call(client.failThenSucceed)(request)
      .sink(
        receiveCompletion: { switch $0 {
          case .failure(let error):
            if error.status.code == .failedPrecondition {
              promise.fulfill()
            }
          case .finished:
            XCTFail("Call should fail, but was completed")
        }},
        receiveValue: { response in
          XCTFail("Call should fail, but got response: " + response.debugDescription)
        }
      )
      .store(in: &Self.retainedCancellables)
    
    wait(for: [promise], timeout: 0.2)
  }
  
  func testAuthenticatedRpcScenario() {
    let promise = expectation(description: "Call gets retried with authentication and succeeds")
    let client = Self.client!
    // The first call is unauthenticated
    let callOptions = CurrentValueSubject<CallOptions, Never>(CallOptions())
    
    let grpc = GRPCExecutor(
      callOptions: callOptions.eraseToAnyPublisher(),
      retry: .failedCall(upTo: 1, when: { $0.status.code == .unauthenticated }, delayUntilNext: { retryCount in
        XCTAssert(retryCount <= 1)
        // Subsequent calls are authenticated
        callOptions.send(CallOptions(customMetadata: HPACKHeaders([("authorization", "Bearer xxx")])))
        return Just(()).eraseToAnyPublisher()
      })
    )
    
    grpc.call(client.authenticatedRpc)(EchoRequest.with { $0.message = "hello" })
      .sink(
        receiveCompletion: { switch $0 {
          case .failure(let status):
            XCTFail("Unexpected status: " + status.localizedDescription)
          case .finished:
            promise.fulfill()
        }},
        receiveValue: { response in
          XCTAssert(response.message == "hello")
        }
      )
      .store(in: &Self.retainedCancellables)
    
    wait(for: [promise], timeout: 0.2)
  }
  
  static var allTests = [
    ("Number of retries not exceeded", testRetriesNotExceeded),
    ("Number of retries exceeded, gave up", testRetriesExceededGaveUp),
    ("Retry status does not match", testRetryStatusDoesNotMatch),
    ("Authenticated RPC scenario", testAuthenticatedRpcScenario),
  ]
}
