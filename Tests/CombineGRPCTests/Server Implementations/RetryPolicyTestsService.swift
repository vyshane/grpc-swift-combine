// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Foundation
import Combine
import GRPC
import NIO
@testable import CombineGRPC

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
class RetryPolicyTestsService: RetryScenariosProvider {

  var interceptors: RetryScenariosServerInterceptorFactoryProtocol?
  var failureCounts: [String: UInt32] = [:]
  
  // Fails with gRPC status failed precondition for the requested number of times, then succeeds.
  func failThenSucceed(request: FailThenSucceedRequest, context: StatusOnlyCallContext) -> EventLoopFuture<FailThenSucceedResponse>
  {
    handle(context) {
      let status = GRPCStatus(code: .failedPrecondition, message: "Requested failure")
      let error: AnyPublisher<FailThenSucceedResponse, RPCError> =
        Fail(error: RPCError(status: status)).eraseToAnyPublisher()
      
      if failureCounts[request.key] == nil {
        failureCounts[request.key] = 1
        return error
      }
      if failureCounts[request.key]! < request.numFailures {
        failureCounts[request.key]! += 1
        return error
      }
      return Just(FailThenSucceedResponse.with { $0.numFailures = failureCounts[request.key]! })
        .setFailureType(to: RPCError.self)
        .eraseToAnyPublisher()
    }
  }
  
  func authenticatedRpc(request: EchoRequest, context: StatusOnlyCallContext) -> EventLoopFuture<EchoResponse> {
    handle(context) {
      if context.headers.contains(where: { $0.0 == "authorization" && $0.1 == "Bearer xxx" }) {
        return Just(EchoResponse.with { $0.message = request.message })
          .setFailureType(to: RPCError.self)
          .eraseToAnyPublisher()
      }
      let status = GRPCStatus(code: .unauthenticated, message: "Missing expected authorization header")
      return Fail(error: RPCError(status: status))
        .eraseToAnyPublisher()
    }
  }
  
  func reset() {
    failureCounts = [:]
  }
}
