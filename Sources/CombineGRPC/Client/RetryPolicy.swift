// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Combine
import GRPC

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public enum RetryPolicy {
  /// Automatically retry failed calls
  ///
  /// - Parameters:
  ///   - upTo: Maximum number of retries
  ///   - when: Retry when condition is true
  ///   - delayUntilNext: Wait for the next published value before retrying. Defaults to a publisher that immediately publishes,
  ///       effectively meaning that there is no delay between retries. `delayUntilNext` is given the current retry count.
  ///   - onGiveUp: Called when number of retries have been exhausted. Defaults to no-op.
  ///
  /// The following example defines a `RetryPolicy` for retrying failed calls up to 3 times when the error is a `GRPCStatus.unavailable`:
  ///
  /// ```
  ///    let retry = RetryPolicy.failedCall(upTo: 3, when: { $0.code == .unavailable }))
  /// ```
  case failedCall(upTo: Int,
                  when: (GRPCStatus) -> Bool,
                  delayUntilNext: (Int) -> AnyPublisher<Void, Never> = { _ in Just(()).eraseToAnyPublisher() },
                  onGiveUp: () -> Void = {})
  /// No automatic retries
  case never
}
