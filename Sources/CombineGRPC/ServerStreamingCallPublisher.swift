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

public struct ServerStreamingCallPublisher<A, B>: Combine.Publisher where A: Message, B: Message {
  public typealias Output = B
  public typealias Failure = Error
  
  public var call: ServerStreamingCall<A, B>? = nil
  
  public let responseHandler: (B) -> Void = { response in
    // TODO
  }
  
  @available(OSX 10.15, *)
  public func receive<S>(subscriber: S)
    where S : Subscriber, ServerStreamingCallPublisher.Failure == S.Failure, ServerStreamingCallPublisher.Output == S.Input
  {
    // TODO
  }
}
