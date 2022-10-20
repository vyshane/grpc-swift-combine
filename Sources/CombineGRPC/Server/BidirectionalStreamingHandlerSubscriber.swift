// Copyright 2019, ComgineGRPC
// Licensed under the Apache License, Version 2.0

import Foundation
import Combine
import GRPC
import NIO
import SwiftProtobuf

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
class BidirectionalStreamingHandlerSubscriber<Request, Response>: Subscriber, Cancellable where Response: Message {
  typealias Input = Response
  typealias Failure = RPCError
  
  private var subscription: Subscription?
  private let context: StreamingResponseCallContext<Response>
  
  init(context: StreamingResponseCallContext<Response>) {
    self.context = context
  }
  
  func receive(subscription: Subscription) {
    self.subscription = subscription
    self.subscription?.request(.max(1))
  }
  
  func receive(_ input: Response) -> Subscribers.Demand {
    _ = context.sendResponse(input)
    return .max(1)
  }
  
  func receive(completion: Subscribers.Completion<RPCError>) {
    switch completion {
    case .failure(let error):
      if context.eventLoop.inEventLoop {
        context.trailers = augment(headers: context.trailers, with: error)
        context.statusPromise.fail(error.status)
      } else {
        context.eventLoop.execute {
          self.context.trailers = augment(headers: self.context.trailers, with: error)
          self.context.statusPromise.fail(error.status)
        }
      }
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
