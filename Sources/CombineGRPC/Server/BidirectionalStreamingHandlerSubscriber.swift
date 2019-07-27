// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Foundation
import Combine
import GRPC
import NIO
import SwiftProtobuf

@available(OSX 10.15, *)
class BidirectionalStreamingHandlerSubscriber<Request, Response>: Subscriber, Cancellable where Response: Message {
  typealias Input = Response
  typealias Failure = GRPCStatus
  
  private var subscription: Subscription?
  private let context: StreamingResponseCallContext<Response>
    
  init(context: StreamingResponseCallContext<Response>) {
    self.context = context
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
      context.statusPromise.fail(status)
    case .finished:
      context.statusPromise.succeed(.ok)
    }
  }
  
  func cancel() {
    subscription?.cancel()
  }
  
  deinit {
    // Ensure that we don't leak the promise
    context.statusPromise
      .fail(GRPCStatus(code: .deadlineExceeded, message: "Handler didn't complete within the deadline"))
  }
}
