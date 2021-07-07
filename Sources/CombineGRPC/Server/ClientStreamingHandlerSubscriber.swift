// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Foundation
import Combine
import GRPC
import NIO
import SwiftProtobuf

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
class ClientStreamingHandlerSubscriber<Request, Response>: Subscriber, Cancellable where Request: Message, Response: Message {
  typealias Input = Response
  typealias Failure = RPCError
  
  private var subscription: Subscription?
  private let context: UnaryResponseCallContext<Response>
    
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
  
  func receive(completion: Subscribers.Completion<RPCError>) {
    switch completion {
    case .failure(let error):
      context.trailers = augment(headers: context.trailers, with: error)
      context.responsePromise.fail(error.status)
    case .finished:
      let status = GRPCStatus(code: .aborted, message: "Handler completed without a response")
      context.responsePromise.fail(status)
    }
  }
  
  func cancel() {
    subscription?.cancel()
  }
}
