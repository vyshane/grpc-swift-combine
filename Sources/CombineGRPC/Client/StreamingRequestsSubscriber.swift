// Copyright 2019, CombineGRPC
// Licensed under the Apache License, Version 2.0

import Combine
import GRPC
import NIOHPACK

class StreamingRequestsSubscriber<Call, Request, Response, DownstreamSubscriber>: Subscriber, Subscription
where Call: StreamingRequestClientCall, Call.RequestPayload == Request, Call.ResponsePayload == Response,
      DownstreamSubscriber: Subscriber, DownstreamSubscriber.Input == Response, DownstreamSubscriber.Failure == RPCError {

  typealias Input = Request
  typealias Failure = Error

  let call: Call
  var buffer: DemandBuffer<DownstreamSubscriber>
  var subscription: Subscription?

  init(call: Call, buffer: DemandBuffer<DownstreamSubscriber>) {
    self.call = call
    self.buffer = buffer
  }

  func receive(subscription: Subscription) {
    self.subscription = subscription

    // Save any trailingMetadata received before status
    var trailingMetadata: HPACKHeaders?
    call.trailingMetadata
      .whenSuccess { metadata in
        trailingMetadata = metadata
      }

    // Send completion as soon as status is available & the subscription has been received
    call.status
      .whenSuccess { status in

        switch status.code {
        case .ok:
          self.complete()

        default:
          self.complete(error: RPCError(status: status, trailingMetadata: trailingMetadata))
        }
      }

    subscription.request(.max(1))
  }

  func receive(_ input: Request) -> Subscribers.Demand {

    call.sendMessage(input)
      .whenComplete { result in

        switch result {
        case .success:

          self.subscription?.request(.max(1))

        case .failure(let error):

          self.complete(error: .from(
            error: error,
            statusCode: .dataLoss,
            message: "Request Stream Send Message Failed"
          ))

          self.call.cancel(promise: nil)
        }
      }

    return .none
  }

  func receive(completion: Subscribers.Completion<Failure>) {

    if case .failure(let error) = completion {

      self.complete(error: .from(
        error: error,
        statusCode: .dataLoss,
        message: "Request Stream Failed"
      ))

      self.call.cancel(promise: nil)

      return
    }

    call.sendEnd()
      .whenComplete { result in

        if case .failure(let error) = completion {

          self.complete(error: .from(
            error: error,
            statusCode: .dataLoss,
            message: "Request Stream Send End Failed"
          ))
        }
      }
  }

  func request(_ demand: Subscribers.Demand) {
    _ = buffer.demand(demand)
  }

  func cancel() {

    call.cancel(promise: nil)

    subscription?.cancel()
    subscription = nil
  }

  func complete(error: RPCError? = nil) {

    if let error = error {

      buffer.complete(completion: .failure(error))

      subscription?.cancel()

    } else {

      buffer.complete(completion: .finished)
    }

    self.subscription = nil
  }

}
