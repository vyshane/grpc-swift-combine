// Copyright 2019, ComgineGRPC
// Licensed under the Apache License, Version 2.0

import Foundation
import Combine
import GRPC
import NIO
import SwiftProtobuf

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
class UnaryHandlerSubscriber<Response>: Subscriber, Cancellable {
  typealias Input = Response
  typealias Failure = RPCError
  
  var futureResult: EventLoopFuture<Response> {
    get {
      responsePromise.futureResult
    }
  }
  
  private var subscription: Subscription?
  private let context: StatusOnlyCallContext
  private let responsePromise: EventLoopPromise<Response>

  init(context: StatusOnlyCallContext) {
    self.context = context
    responsePromise = context.eventLoop.makePromise()
  }
  
  func receive(subscription: Subscription) {
    self.subscription = subscription
    self.subscription?.request(.max(1))
  }
  
  func receive(_ input: Response) -> Subscribers.Demand {
    responsePromise.succeed(input)
    return .max(1)
  }
  
  func receive(completion: Subscribers.Completion<RPCError>) {
    switch completion {
    case .failure(let error):
      context.trailers = augment(headers: context.trailers, with: error)
      responsePromise.fail(error.status)
    case .finished:
      let status = GRPCStatus(code: .aborted, message: "Response publisher completed without sending a value")
      responsePromise.fail(status)
    }
  }
  
  func cancel() {
    subscription?.cancel()
  }
}
