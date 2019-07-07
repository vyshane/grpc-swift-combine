//
//  CallPublisherUtils.swift
//  CombineGRPC
//
//  Created by Vy-Shane Xie on 7/7/19.
//

import Foundation
import Combine
import GRPC

@available(OSX 10.15, *)
func sendCompletion<S>(toSubscriber: S, forStatus: GRPCStatus) -> Void
  where S: Subscriber, S.Failure == StatusError
{
  switch forStatus.code {
  case .ok:
    toSubscriber.receive(completion: .finished)
  default:
    toSubscriber.receive(completion: .failure(StatusError(code: forStatus.code, message: forStatus.message)))
  }
}
