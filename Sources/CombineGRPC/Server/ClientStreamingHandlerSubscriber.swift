// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Foundation
import Combine
import GRPC
import NIO
import SwiftProtobuf

@available(OSX 10.15, *)
class ClientStreamingHandlerSubscriber<Request, Response>: Subscriber, Cancellable where Request: Message, Response: Message {
  typealias Input = Response
  typealias Failure = GRPCStatus
  
  var subscription: Subscription?
  var context: UnaryResponseCallContext<Response>
  var futureStreamEventProcessor: EventLoopFuture<(StreamEvent<Request>) -> Void>?
    
  init(context: UnaryResponseCallContext<Response>) {
    self.context = context
  }
  
  func receive(subscription: Subscription) {
    self.subscription = subscription
    self.subscription?.request(.max(1))
  }
  
  func receive(_ input: Response) -> Subscribers.Demand {
    context.responsePromise.succeed(input)
    return .max(1)
  }
  
  func receive(completion: Subscribers.Completion<GRPCStatus>) {
    switch completion {
    case .failure(let status):
      context.responsePromise.fail(status)
    case .finished:
      context.responsePromise.fail(GRPCStatus(code: .aborted, message: "Handler completed without a response"))
    }
  }
  
  func cancel() {
    subscription?.cancel()
  }
}

