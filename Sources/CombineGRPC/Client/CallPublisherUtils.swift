// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Foundation
import Combine
import GRPC
import NIO
import NIOHPACK
import NIOHTTP1

@available(OSX 10.15, iOS 13, tvOS 13, *)
func sendCompletion<Response>(
  status: EventLoopFuture<GRPCStatus>,
  trailingMetadata: EventLoopFuture<HPACKHeaders>,
  toSubscriber: Publishers.Create<Response, RPCError>.Subscriber
) -> Void {
  var resolvedMetadata: HPACKHeaders?
  
  // Trailing metadata will be available before status.
  trailingMetadata.whenSuccess { resolvedMetadata = $0 }
  
  status.whenSuccess { status in
    switch status.code {
    case .ok:
      toSubscriber.send(completion: .finished)
    default:
      let error = RPCError(status: status, trailingMetadata: resolvedMetadata)
      toSubscriber.send(completion: .failure(error))
    }
  }
}
