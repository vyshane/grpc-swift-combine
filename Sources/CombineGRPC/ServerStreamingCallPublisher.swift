//
//  ServerStreamingCallPublisher.swift
//  CombineGRPC
//
//  Created by Vy-Shane Xie on 4/7/19.
//

import Foundation
import Combine
import GRPC
import SwiftProtobuf

@available(OSX 10.15, *)
public struct ServerStreamingCallPublisher<Request, Response>: Publisher where Request: Message, Response: Message {
  public typealias Output = Response
  public typealias Failure = StatusError
  
  let call: ServerStreamingCall<Request, Response>
  let bridge: MessageBridge<Response>
  
  init(serverStreamingCall: ServerStreamingCall<Request, Response>, messageBridge: MessageBridge<Response>) {
    call = serverStreamingCall
    bridge = messageBridge
  }
  
  public func receive<S>(subscriber: S)
    where S : Subscriber, ServerStreamingCallPublisher.Failure == S.Failure, ServerStreamingCallPublisher.Output == S.Input
  {
    _ = bridge.messages.map(subscriber.receive)
    call.status.whenSuccess { sendCompletion(toSubscriber: subscriber, forStatus: $0) }
  }
}
