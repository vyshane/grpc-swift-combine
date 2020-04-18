// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Foundation
import Combine
import GRPC
import SwiftProtobuf

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
struct ServerStreamingCallPublisher<Request, Response>: Publisher where Request: GRPCPayload, Response: GRPCPayload {
  typealias Output = Response
  typealias Failure = GRPCStatus
  
  private let call: ServerStreamingCall<Request, Response>
  private let bridge: MessageBridge<Response>
  
  init(serverStreamingCall: ServerStreamingCall<Request, Response>, messageBridge: MessageBridge<Response>) {
    call = serverStreamingCall
    bridge = messageBridge
  }
  
  func receive<S>(subscriber: S)
    where S : Subscriber, ServerStreamingCallPublisher.Failure == S.Failure,
    ServerStreamingCallPublisher.Output == S.Input
  {    
    bridge.messagePublisher.subscribe(subscriber)
    // Call status future always succeeds and signals call failure via gRPC status
    call.status.whenSuccess { sendCompletion(status: $0, toSubscriber: subscriber) }
  }
}
