// Copyright 2019, ComgineGRPC
// Licensed under the Apache License, Version 2.0

import XCTest
import Combine
import GRPC
import NIOHPACK
@testable import CombineGRPC

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
        receiveCompletion: expectFinished(resolve: promise),
        receiveValue: expectValue { response in
          Int(response.numFailures) == 2
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
        receiveCompletion: expectRPCError(code: .failedPrecondition, resolve: callPromise),
        receiveValue: expectNoValue()
      )
      .store(in: &Self.retainedCancellables)
    
    wait(for: [callPromise, onGiveUpPromise], timeout: 0.2)
  }

  func testDelayUntilNextParameters() {
    let promise = expectation(description: "Call fails twice, then succeeds")
    let client = Self.client!
    var delayUntilNextFinalRetryCount = 0

    let grpc = GRPCExecutor(retry: .failedCall(
      upTo: 99,
      when: { $0.status.code == .failedPrecondition },
      delayUntilNext: { count, error in
        XCTAssert(error.status.code == .failedPrecondition)
        delayUntilNextFinalRetryCount = count
        return Just(()).eraseToAnyPublisher()
      }
    ))

    let request = FailThenSucceedRequest.with {
      $0.key = "testDelayUntilNextParameters"
      $0.numFailures = 2
    }

    grpc.call(client.failThenSucceed)(request)
      .sink(
        receiveCompletion: expectFinished(resolve: promise, onFinished: {
          XCTAssert(delayUntilNextFinalRetryCount == 2)
        }),
        receiveValue: { _ in }
      )
      .store(in: &Self.retainedCancellables)

    wait(for: [promise], timeout: 0.2)
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
        receiveCompletion: expectRPCError(code: .failedPrecondition, resolve: promise),
        receiveValue: expectNoValue()
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
      retry: .failedCall(upTo: 1, when: { $0.status.code == .unauthenticated }, delayUntilNext: { retryCount, error in
        XCTAssert(retryCount <= 1)
        XCTAssert(error.status.code == .unauthenticated)
        // Subsequent calls are authenticated
        callOptions.send(CallOptions(customMetadata: HPACKHeaders([("authorization", "Bearer xxx")])))
        return Just(()).eraseToAnyPublisher()
      })
    )
    
    grpc.call(client.authenticatedRpc)(EchoRequest.with { $0.message = "hello" })
      .sink(
        receiveCompletion: expectFinished(resolve: promise),
        receiveValue: expectValue { $0.message == "hello" }
      )
      .store(in: &Self.retainedCancellables)
    
    wait(for: [promise], timeout: 0.2)
  }
  
  static var allTests = [
    ("Number of retries not exceeded", testRetriesNotExceeded),
    ("Number of retries exceeded, gave up", testRetriesExceededGaveUp),
    ("delayUntilNext is called with expected parameters", testDelayUntilNextParameters),
    ("Retry status does not match", testRetryStatusDoesNotMatch),
    ("Authenticated RPC scenario", testAuthenticatedRpcScenario),
  ]
}
