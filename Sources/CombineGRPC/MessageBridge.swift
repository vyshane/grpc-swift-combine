//
//  MessageBridge.swift
//  CombineGRPC
//
//  Created by Vy-Shane Xie on 5/7/19.
//

import Foundation
import Combine

@available(OSX 10.15, *)
struct MessageBridge<T> {
  let messages = PassthroughSubject<T, Error>()
  
  public func receive(message: T) -> Void {
    _ = messages.append(message)
  }
}
