// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Foundation
import Combine
import GRPC
import SwiftProtobuf
import NIOHPACK
import NIO

class BidirectionalStreamingPublisher<REQ, RES, RP>: Publisher
where RP: Publisher, RP.Output == REQ, RP.Failure == Error, REQ: Message, RES: Message {

  typealias Output = RES
  typealias Failure = RPCError

  let rpc: BidirectionalStreamingRPC<REQ, RES>
  let callOptions: CallOptions
  let requests: RP

  init(rpc: @escaping BidirectionalStreamingRPC<REQ, RES>, callOptions: CallOptions, requests: RP) {
    self.rpc = rpc
    self.callOptions = callOptions
    self.requests = requests
  }

  func receive<S>(subscriber: S) where S : Subscriber, S.Input == Output, S.Failure == RPCError {

    let buffer = DemandBuffer(subscriber: subscriber)

    let call = rpc(callOptions) { _ = buffer.buffer(value: $0) }

    let requestsSubscriber = StreamingRequestsSubscriber(call: call, buffer: buffer)
    subscriber.receive(subscription: requestsSubscriber)
    requests.subscribe(requestsSubscriber)
  }

}
