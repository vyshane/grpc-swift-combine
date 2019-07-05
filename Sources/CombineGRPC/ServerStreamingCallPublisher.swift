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
public struct ServerStreamingCallPublisher<A, B>: Publisher where A: Message, B: Message {
  public typealias Output = B
  public typealias Failure = Error
  
  let call: ServerStreamingCall<A, B>
  let bridge: MessageBridge<B>
  
  init(serverStreamingCall: ServerStreamingCall<A, B>, messageBridge: MessageBridge<B>) {
    call = serverStreamingCall
    bridge = messageBridge
  }
  
  public func receive<S>(subscriber: S)
    where S : Subscriber, ServerStreamingCallPublisher.Failure == S.Failure, ServerStreamingCallPublisher.Output == S.Input
  {
    _ = bridge.messages.map { subscriber.receive($0) }
    
    // TODO
    // Status of the gRPC call after it has ended
//    call.status
  }
}
