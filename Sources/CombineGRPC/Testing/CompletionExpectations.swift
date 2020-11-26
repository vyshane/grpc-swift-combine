// Copyright 2020, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0
//
// CompletionExpectation is a collection of useful functions for asserting how you
// expect publishers to behave in your tests.
//
// For usage examples, look at CombineGRPCTests.

import Combine
import GRPC
import XCTest

@available(OSX 10.15, iOS 13, tvOS 13, *)
public func expectFinished<E>(resolve expectation: XCTestExpectation? = nil, onFinished: () -> Void = {})
  -> (_ actual: Subscribers.Completion<E>) -> Void where E: Error
{
  { actual in
    switch actual {
    case .failure(let actualError):
      XCTFail("Expecting Completion.finished but got \(actualError)")
    case .finished:
      expectation?.fulfill()
    }
  }
}

@available(OSX 10.15, iOS 13, tvOS 13, *)
public func resolve<T>
  (_ expectation: XCTestExpectation? = nil, expectingFailure check: @escaping (T) -> Bool)
  -> (_ actual: Subscribers.Completion<T>)
  -> Void
{
  { actual in
    switch actual {
    case .failure(let actualError):
      if check(actualError) {
        expectation?.fulfill()
      } else {
        XCTFail("Got unexpected error \(actual)")
      }
    case .finished:
      XCTFail("Expecting Completion.failure but got Completion.finished")
    }
  }
}

@available(OSX 10.15, iOS 13, tvOS 13, *)
public func expectFailure<T>(_ check: @escaping (T) -> Bool, resolve expectation: XCTestExpectation? = nil)
  -> (_ actual: Subscribers.Completion<T>)
  -> Void
{
  { actual in
    switch actual {
    case .failure(let actualError):
      if check(actualError) {
        expectation?.fulfill()
      } else {
        XCTFail("Got unexpected error \(actual)")
      }
    case .finished:
      XCTFail("Expecting Completion.failure but got Completion.finished")
    }
  }
}

@available(OSX 10.15, iOS 13, tvOS 13, *)
public func expectRPCError(code: GRPCStatus.Code, message: String? = nil, resolve expectation: XCTestExpectation? = nil)
  -> (_ actual: Subscribers.Completion<RPCError>)
  -> Void
{
  { actual in
    switch actual {
    case .failure(let actualError):
      if actualError.status.code == code && (message == nil || actualError.status.message == message) {
        expectation?.fulfill()
      } else {
        XCTFail("Expecting (\(code), \(message ?? "nil")) " +
          "but got (\(actualError.status), \(actualError.status.message ?? "nil"))")
      }
    case .finished:
      XCTFail("Expecting Completion.failure but got Completion.finished")
    }
  }
}

public func expectValue<T>(_ check: @escaping (T) -> Bool) -> (_ value: T) -> Void {
  { value in
    XCTAssert(check(value))
  }
}

public func expectNoValue<T>() -> (_ value: T) -> Void {
  { _ in
    XCTFail("Unexpected value")
  }
}
