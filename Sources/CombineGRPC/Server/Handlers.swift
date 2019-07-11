// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Combine
import GRPC
import NIO
import SwiftProtobuf

// MARK: Unary

@available(OSX 10.15, *)
public func handle<Response>(_ context: StatusOnlyCallContext,
                             handler: () -> AnyPublisher<Response, GRPCStatus>) -> EventLoopFuture<Response>
{
  let unarySubscriber = UnaryHandlerSubscriber<Response>(context: context)
  _ = handler().subscribe(unarySubscriber)
  return unarySubscriber.promise.futureResult
}

@available(OSX 10.15, *)
public func handle<Request, Response>(_ request: Request, _ context: StatusOnlyCallContext,
                                      handler: (Request) -> AnyPublisher<Response, GRPCStatus>)
                                     -> EventLoopFuture<Response>
{
  let unarySubscriber = UnaryHandlerSubscriber<Response>(context: context)
  _ = handler(request).subscribe(unarySubscriber)
  return unarySubscriber.promise.futureResult
}

// MARK: Server Streaming

// TODO

// MARK: Client Streaming

// TODO

// MARK: Bidirectional Streaming

// TODO
