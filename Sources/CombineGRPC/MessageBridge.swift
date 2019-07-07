// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Foundation
import Combine

@available(OSX 10.15, *)
struct MessageBridge<T> {
  let messages = PassthroughSubject<T, Error>()
  
  func receive(message: T) -> Void {
    _ = messages.append(message)
  }
}
