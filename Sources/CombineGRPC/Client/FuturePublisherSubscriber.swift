// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Foundation
import Combine
import GRPC

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
class FuturePublisherSubscriber<T>: Subscriber, Cancellable {
  typealias Input = T
  typealias Failure = GRPCStatus
  
  var future: Future<T, GRPCStatus> = Future { _ in }
  private var promise: Future<T, GRPCStatus>.Promise?
  private var subscription: Subscription?
  
  func receive(subscription: Subscription) {
    future = Future { promise in
      self.promise = promise
    }
    self.subscription = subscription
    self.subscription?.request(.max(1))
  }
  
  func receive(_ input: T) -> Subscribers.Demand {
    promise?(.success(input))
    return .max(1)
  }
  
  func receive(completion: Subscribers.Completion<GRPCStatus>) {
    if case let .failure(status) = completion {
      promise?(.failure(status))
    }
  }
  
  func cancel() {
    subscription?.cancel()
  }
}
