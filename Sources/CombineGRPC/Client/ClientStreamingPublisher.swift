// Copyright 2019, ComgineGRPC
// Licensed under the Apache License, Version 2.0

import Foundation
import Combine
import GRPC
import SwiftProtobuf
import NIOHPACK
import NIO
import CombineExt

class ClientStreamingPublisher<Request, Response, RequestPublisher>: Publisher
where RequestPublisher: Publisher, RequestPublisher.Output == Request, RequestPublisher.Failure == Error, Request: Message, Response: Message {

  typealias Output = Response
  typealias Failure = RPCError

  let rpc: ClientStreamingRPC<Request, Response>
  let callOptions: CallOptions
  let requests: RequestPublisher

  init(rpc: @escaping ClientStreamingRPC<Request, Response>, callOptions: CallOptions, requests: RequestPublisher) {
    self.rpc = rpc
    self.callOptions = callOptions
    self.requests = requests
  }

  func receive<S>(subscriber: S) where S : Subscriber, S.Input == Output, S.Failure == RPCError {

    let buffer = DemandBuffer(subscriber: subscriber)

    let call = rpc(callOptions)
    call.response.whenSuccess { _ = buffer.buffer(value: $0) }

    let requestsSubscriber = StreamingRequestsSubscriber(call: call, buffer: buffer)
    subscriber.receive(subscription: requestsSubscriber)
    requests.subscribe(requestsSubscriber)
  }

}
