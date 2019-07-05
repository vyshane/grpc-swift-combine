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

public struct UnaryCallPublisher<Request, Response>: Publisher where Request: Message, Response: Message {
  public typealias Output = Response
  public typealias Failure = Error
  
  let call: UnaryCall<Request, Response>
  
  init(unaryCall: UnaryCall<Request, Response>) {
    call = unaryCall
  }
  
  @available(OSX 10.15, *)
  public func receive<S>(subscriber: S)
    where S : Subscriber, UnaryCallPublisher.Failure == S.Failure, UnaryCallPublisher.Output == S.Input
  {
    call.response.whenSuccess { response in
      _ = subscriber.receive(response)
    }
    call.response.whenFailure { error in
      _ = subscriber.receive(completion: Subscribers.Completion.failure(error))
    }
  }
}
