// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Combine
import GRPC

/**
 Specifies retry behaviour when a gRPC call fails.
*/
@available(OSX 10.15, iOS 13, tvOS 13, *)
public enum RetryPolicy {
  /**
   Automatically retry failed calls up to a maximum number of times, when a condition is met.
   
   - Parameters:
     - upTo: Maximum number of retries. Defaults to 1.
     - when: Retry when condition is true.
     - delayUntilNext: Wait for the next published value before retrying. Defaults to a publisher that immediately
       effectively meaning that there is no delay between retries. `delayUntilNext` is given the current retry count.
     - didGiveUp: Called when number of retries have been exhausted. Defaults to no-op.
   
   The following example defines a `RetryPolicy` for retrying failed calls up to 3 times when the error is a `GRPCStatus.unavailable`:
  
   ```
   let retry = RetryPolicy.failedCall(upTo: 3, when: { $0.code == .unavailable }))
   ```
   */
  case failedCall(upTo: UInt = 1,
                  when: (RPCError) -> Bool,
                  delayUntilNext: (Int) -> AnyPublisher<Void, Never> = { _ in Just(()).eraseToAnyPublisher() },
                  didGiveUp: () -> Void = {})
  /**
   No automatic retries.
   */
  case never
}
