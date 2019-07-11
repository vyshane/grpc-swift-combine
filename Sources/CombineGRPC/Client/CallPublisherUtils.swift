// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Foundation
import Combine
import GRPC

@available(OSX 10.15, *)
func sendCompletion<S>(toSubscriber: S, forStatus: GRPCStatus) -> Void
  where S: Subscriber, S.Failure == GRPCStatus
{
  switch forStatus.code {
  case .ok:
    toSubscriber.receive(completion: .finished)
  default:
    toSubscriber.receive(completion: .failure(forStatus))
  }
}
