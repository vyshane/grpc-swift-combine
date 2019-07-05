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
  public typealias Failure = StatusError
  
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
    
    // TODO: Abstract this out
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
