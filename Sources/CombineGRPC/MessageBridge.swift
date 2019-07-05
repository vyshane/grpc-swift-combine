//
//  MessageBridge.swift
//  CombineGRPC
//
//  Created by Vy-Shane Xie on 5/7/19.
//

import Foundation
import Combine

@available(OSX 10.15, *)
struct MessageBridge<A> {
  let messages = PassthroughSubject<A, Error>()
  
  public func receive(message: A) -> Void {
    _ = messages.append(message)
  }
}
