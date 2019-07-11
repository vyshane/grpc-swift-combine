// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Foundation
import Combine
import GRPC
import SwiftProtobuf

@available(OSX 10.15, *)
public struct ServerStreamingCallPublisher<Request, Response>: Publisher where Request: Message, Response: Message {
  public typealias Output = Response
  public typealias Failure = GRPCStatus
  
  let call: ServerStreamingCall<Request, Response>
  let bridge: MessageBridge<Response>
  
  init(serverStreamingCall: ServerStreamingCall<Request, Response>, messageBridge: MessageBridge<Response>) {
    call = serverStreamingCall
    bridge = messageBridge
  }
  
  public func receive<S>(subscriber: S)
    where S : Subscriber, ServerStreamingCallPublisher.Failure == S.Failure,
    ServerStreamingCallPublisher.Output == S.Input
  {
    bridge.messages.receive(subscriber: subscriber)
    call.status.whenSuccess { sendCompletion(toSubscriber: subscriber, forStatus: $0) }
  }
}
