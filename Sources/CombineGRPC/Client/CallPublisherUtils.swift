// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Foundation
import Combine
import GRPC

@available(OSX 10.15, iOS 13, tvOS 13, *)
func sendCompletion<Response>(toSubscriber: Publishers.Create<Response, GRPCStatus>.Subscriber) -> (GRPCStatus) -> Void
{
  { status in
    switch status.code {
    case .ok:
      toSubscriber.send(completion: .finished)
    default:
      toSubscriber.send(completion: .failure(status))
    }
  }
}
