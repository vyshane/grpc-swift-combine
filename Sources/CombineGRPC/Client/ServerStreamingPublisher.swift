// Copyright 2019, ComgineGRPC
// Licensed under the Apache License, Version 2.0

import Foundation
import Combine
import GRPC
import SwiftProtobuf
import NIOHPACK
import NIO

class ServerStreamingPublisher<Request, Response>: Publisher where Request: Message, Response: Message {

  typealias Output = Response
  typealias Failure = RPCError

  let rpc: ServerStreamingRPC<Request, Response>
  let callOptions: CallOptions
  let request: Request

  init(rpc: @escaping ServerStreamingRPC<Request, Response>, callOptions: CallOptions, request: Request) {
    self.rpc = rpc
    self.callOptions = callOptions
    self.request = request
  }

  func receive<S>(subscriber: S) where S : Subscriber, S.Input == Output, S.Failure == RPCError {

    let buffer = DemandBuffer(subscriber: subscriber)

    let call = rpc(request, callOptions) { _ = buffer.buffer(value: $0) }

    subscriber.receive(subscription: ServerStreamingSubscription(call: call, buffer: buffer))
  }

}


class ServerStreamingSubscription<Request, Response, DownstreamSubscriber>: Subscription
where DownstreamSubscriber: Subscriber, DownstreamSubscriber.Failure == RPCError {

  typealias Input = Request
  typealias Failure = Error
  typealias Call = ServerStreamingCall<Request, Response>

  let call: Call
  var buffer: DemandBuffer<DownstreamSubscriber>

  init(call: Call, buffer: DemandBuffer<DownstreamSubscriber>) {
    self.call = call
    self.buffer = buffer

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
  }

  func request(_ demand: Subscribers.Demand) {
    _ = buffer.demand(demand)
  }

  func cancel() {

    call.cancel(promise: nil)
  }

  func complete(error: RPCError? = nil) {

    if let error = error {

      buffer.complete(completion: .failure(error))

    } else {

      buffer.complete(completion: .finished)
    }
  }

}
