// Copyright 2019, ComgineGRPC
// Licensed under the Apache License, Version 2.0

import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
  return [
    testCase(UnaryTests.allTests),
    testCase(ClientStreamingTests.allTests),
    testCase(ServerStreamingTests.allTests),
    testCase(BidirectionalStreamingTests.allTests),
    testCase(RetryPolicyTests.allTests),
  ]
}
#endif
