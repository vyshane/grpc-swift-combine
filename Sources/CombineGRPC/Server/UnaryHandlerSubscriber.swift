// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Foundation
import Combine
import GRPC
import NIO
import SwiftProtobuf

@available(OSX 10.15, *)
class UnaryHandlerSubscriber<Response>: Subscriber, Cancellable {
  typealias Input = Response
  typealias Failure = GRPCStatus
  
  var futureResult: EventLoopFuture<Response> {
    get {
      return promise.futureResult
    }
  }
  
  private var subscription: Subscription?
  private let promise: EventLoopPromise<Response>
  
  init(context: StatusOnlyCallContext) {
    self.promise = context.eventLoop.makePromise()
  }
  
  func receive(subscription: Subscription) {
    self.subscription = subscription
    self.subscription?.request(.max(1))
  }
  
  func receive(_ input: Response) -> Subscribers.Demand {
    promise.succeed(input)
    return .max(1)
  }
  
  func receive(completion: Subscribers.Completion<GRPCStatus>) {
    switch completion {
    case .failure(let status):
      promise.fail(status)
    case .finished:
      let status = GRPCStatus(code: .aborted, message: "Response publisher completed without sending a value")
      promise.fail(status)
    }
  }
  
  func cancel() {
    subscription?.cancel()
  }
}
