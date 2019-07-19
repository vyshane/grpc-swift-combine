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
    
    // Client subscription is cancelled before server emits:
    
//    receive subscription: (PassthroughSubject)
//    request unlimited
//    receive cancel
    
    // Server:
    
//    receive subscription: (Sequence)
//    request unlimited
//    receive value: (CombineGRPCTests.EchoResponse:
//    message: "hello"
//    )
//    request unlimited (synchronous)
//    receive value: (CombineGRPCTests.EchoResponse:
//    message: "hello"
//    )
//    request unlimited (synchronous)
//    receive value: (CombineGRPCTests.EchoResponse:
//    message: "hello"
//    )
//    request unlimited (synchronous)
//    receive finished
    
    bridge.messagePublisher
      .print()
      .breakpoint(receiveOutput: { _ in true }, receiveCompletion: { _ in true })
      .receive(subscriber: subscriber)
    
    // Call status future always succeeds and signals call failure via gRPC status
    call.status.whenSuccess { sendCompletion(toSubscriber: subscriber, forStatus: $0) }
  }
}
