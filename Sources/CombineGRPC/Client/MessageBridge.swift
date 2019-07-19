// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Foundation
import Combine
import GRPC

@available(OSX 10.15, *)
struct MessageBridge<T> {
  let messagePublisher = PassthroughSubject<T, GRPCStatus>()
  
  func receive(message: T) -> Void {
    messagePublisher.send(message)
  }
}
