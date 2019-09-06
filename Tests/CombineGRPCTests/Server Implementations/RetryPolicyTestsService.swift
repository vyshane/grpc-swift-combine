// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Foundation
import Combine
import GRPC
import NIO
@testable import CombineGRPC

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
class RetryPolicyTestsService: RetryScenariosProvider {
  
  let failureStatus: AnyPublisher<FailThenSucceedResponse, GRPCStatus> =
    Fail(error: GRPCStatus(code: .failedPrecondition, message: "Requested failure")).eraseToAnyPublisher()
  
  var failureCount: [String: UInt32] = [:]
  
  // Fails with gRPC status failed precondition for the requested number of times, then succeeds
  func failThenSucceed(request: FailThenSucceedRequest, context: StatusOnlyCallContext) -> EventLoopFuture<FailThenSucceedResponse>
  {
    handle(context) {
      if failureCount[request.key] == nil {
        failureCount[request.key] = 1
        return failureStatus
      }
      if failureCount[request.key]! < request.numFailures {
        failureCount[request.key]! += 1
        return failureStatus
      }
      return Just(FailThenSucceedResponse.with { $0.numFailures = failureCount[request.key]! })
        .setFailureType(to: GRPCStatus.self)
        .eraseToAnyPublisher()
    }
  }
  
  func reset() {
    failureCount = [:]
  }
}
