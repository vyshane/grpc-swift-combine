// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Foundation
import Combine

class DemandBuffer<S: Subscriber> {

  struct Demand {
    var processed: Subscribers.Demand = .none
    var requested: Subscribers.Demand = .none
    var sent: Subscribers.Demand = .none
  }

  private let lock = NSRecursiveLock()
  private var buffer = [S.Input]()
  private let subscriber: S
  private var completion: Subscribers.Completion<S.Failure>?
  private var currentDemand = Demand()

  init(subscriber: S) {
    self.subscriber = subscriber
  }

  func buffer(value: S.Input) -> Subscribers.Demand {
    precondition(self.completion == nil)
    lock.lock()
    defer { lock.unlock() }

    switch currentDemand.requested {
    case .unlimited:
      return subscriber.receive(value)
    default:
      buffer.append(value)
      return flush()
    }
  }

  func complete(completion: Subscribers.Completion<S.Failure>) {
    precondition(self.completion == nil)

    self.completion = completion
    _ = flush()
  }

  func demand(_ demand: Subscribers.Demand) -> Subscribers.Demand {
    flush(adding: demand)
  }

  private func flush(adding demand: Subscribers.Demand? = nil) -> Subscribers.Demand {
    lock.lock()
    defer { lock.unlock() }

    if let demand = demand {
      currentDemand.requested += demand
    }

    // If buffer isn't ready for flushing, return immediately
    guard currentDemand.requested > 0 || demand == Subscribers.Demand.none else {
      return .none
    }

    while !buffer.isEmpty && currentDemand.processed < currentDemand.requested {
      currentDemand.requested += subscriber.receive(buffer.remove(at: 0))
      currentDemand.processed += 1
    }

    if let completion = completion {
      // Clear waiting events and send completion
      buffer = []
      currentDemand = .init()
      self.completion = nil
      subscriber.receive(completion: completion)
      return .none
    }

    let sentDemand = currentDemand.requested - currentDemand.sent
    currentDemand.sent += sentDemand
    return sentDemand
  }
}
