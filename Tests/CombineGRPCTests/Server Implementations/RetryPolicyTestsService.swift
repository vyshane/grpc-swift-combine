// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Foundation
import Combine
import GRPC
import NIO
@testable import CombineGRPC

@available(OSX 10.15, iOS 13, tvOS 13, *)
class RetryPolicyTestsService: RetryScenariosProvider {
  
  var failureCounts: [String: UInt32] = [:]
  
  // Fails with gRPC status failed precondition for the requested number of times, then succeeds
  func failThenSucceed(request: FailThenSucceedRequest, context: StatusOnlyCallContext) -> EventLoopFuture<FailThenSucceedResponse>
  {
    handle(context) {
      let failureStatus: AnyPublisher<FailThenSucceedResponse, GRPCStatus> =
        Fail(error: GRPCStatus(code: .failedPrecondition, message: "Requested failure")).eraseToAnyPublisher()
      
      if failureCounts[request.key] == nil {
        failureCounts[request.key] = 1
        return failureStatus
      }
      if failureCounts[request.key]! < request.numFailures {
        failureCounts[request.key]! += 1
        return failureStatus
      }
      return Just(FailThenSucceedResponse.with { $0.numFailures = failureCounts[request.key]! })
        .setFailureType(to: GRPCStatus.self)
        .eraseToAnyPublisher()
    }
  }
  
  func authenticatedRpc(request: EchoRequest, context: StatusOnlyCallContext) -> EventLoopFuture<EchoResponse> {
    handle(context) {
      if context.request.headers.contains(where: { $0.0 == "authorization" && $0.1 == "Bearer xxx" }) {
        return Just(EchoResponse.with { $0.message = request.message })
          .setFailureType(to: GRPCStatus.self)
          .eraseToAnyPublisher()
      }
      return Fail(error: GRPCStatus(code: .unauthenticated, message: "Missing expected authorization header"))
        .eraseToAnyPublisher()
    }
  }
  
  func reset() {
    failureCounts = [:]
  }
}
