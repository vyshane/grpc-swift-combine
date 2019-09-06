// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Foundation
import Combine
import GRPC

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
func sendCompletion<S>(status: GRPCStatus, toSubscriber: S) -> Void
  where S: Subscriber, S.Failure == GRPCStatus
{
  switch status.code {
  case .ok:
    toSubscriber.receive(completion: .finished)
  default:
    toSubscriber.receive(completion: .failure(status))
  }
}
