//
//  UnaryCallPublisher.swift
//  CombineGRPC
//
//  Created by Vy-Shane Xie on 3/7/19.
//

import Foundation
import Combine
import GRPC
import SwiftProtobuf

public struct UnaryCallPublisher<A, B>: Combine.Publisher where A: Message, B: Message {
  public typealias Output = B
  public typealias Failure = Error
  
  let call: UnaryCall<A, B>
  
  init(_ unaryCall: UnaryCall<A, B>) {
    call = unaryCall
  }
  
  @available(OSX 10.15, *)
  public func receive<S>(subscriber: S) where S : Subscriber, UnaryCallPublisher.Failure == S.Failure, UnaryCallPublisher.Output == S.Input {
    call.response.whenSuccess { response in
      _ = subscriber.receive(response)
    }
    call.response.whenFailure { error in
      _ = subscriber.receive(completion: Subscribers.Completion.failure(error))
    }
  }
}
