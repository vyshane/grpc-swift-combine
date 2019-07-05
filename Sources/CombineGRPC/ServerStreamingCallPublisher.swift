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
    
    // The status future completes successfully even when there is an error status
    call.status.whenSuccess { status in
      switch status.code {
      case .ok:
        subscriber.receive(completion: .finished)
      default:
        subscriber.receive(completion: .failure(StatusError(code: status.code, message: status.message)))
      }
    }
  }
}
