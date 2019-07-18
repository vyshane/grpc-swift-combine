// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Foundation
import Combine
import GRPC
import NIO
import SwiftProtobuf

@available(OSX 10.15, *)
class ServerStreamingHandlerSubscriber<Response>: Subscriber, Cancellable where Response: Message {
  typealias Input = Response
  typealias Failure = GRPCStatus
  
  var subscription: Subscription?
  var context: StreamingResponseCallContext<Response>
  var futureStatus: EventLoopFuture<GRPCStatus> {
    get {
      return statusPromise.futureResult
    }
  }
  
  private let statusPromise: EventLoopPromise<GRPCStatus>
  
  init(context: StreamingResponseCallContext<Response>) {
    self.context = context
    self.statusPromise = context.eventLoop.makePromise()
  }
  
  func receive(subscription: Subscription) {
    self.subscription = subscription
    self.subscription?.request(.unlimited)
  }
  
  func receive(_ input: Response) -> Subscribers.Demand {
    _ = context.sendResponse(input)
    return .unlimited
  }
  
  func receive(completion: Subscribers.Completion<GRPCStatus>) {
    switch completion {
    case .failure(let status):
      statusPromise.fail(status)
    case .finished:
      statusPromise.succeed(.ok)
    }
  }
  
  func cancel() {
    subscription?.cancel()
  }
}
