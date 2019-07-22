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
  handler().subscribe(unarySubscriber)
  return unarySubscriber.futureResult
}

@available(OSX 10.15, *)
public func handle<Request, Response>(_ request: Request, _ context: StatusOnlyCallContext,
                                      handler: (Request) -> AnyPublisher<Response, GRPCStatus>)
                                     -> EventLoopFuture<Response>
{
  let unarySubscriber = UnaryHandlerSubscriber<Response>(context: context)
  handler(request).subscribe(unarySubscriber)
  return unarySubscriber.futureResult
}

// MARK: Server Streaming

@available(OSX 10.15, *)
public func handle<Response>(_ context: StreamingResponseCallContext<Response>,
                             handler: () -> AnyPublisher<Response, GRPCStatus>) -> EventLoopFuture<GRPCStatus>
{
  let serverStreamingSubscriber = ServerStreamingHandlerSubscriber<Response>(context: context)
  handler().subscribe(serverStreamingSubscriber)
  return serverStreamingSubscriber.futureStatus
}

@available(OSX 10.15, *)
public func handle<Request, Response>(_ request: Request, _ context: StreamingResponseCallContext<Response>,
                                      handler: (Request) -> AnyPublisher<Response, GRPCStatus>)
                                     -> EventLoopFuture<GRPCStatus>
{
  let serverStreamingSubscriber = ServerStreamingHandlerSubscriber<Response>(context: context)
  handler(request).subscribe(serverStreamingSubscriber)
  return serverStreamingSubscriber.futureStatus
}

// MARK: Client Streaming

@available(OSX 10.15, *)
public func handle<Request, Response>(_ context: UnaryResponseCallContext<Response>,
                                      handler: (AnyPublisher<Request, Never>) -> AnyPublisher<Response, GRPCStatus>)
                                     -> EventLoopFuture<(StreamEvent<Request>) -> Void>
{
  let requests = PassthroughSubject<Request, Never>()
  let clientStreamingSubscriber = ClientStreamingHandlerSubscriber<Request, Response>(context: context, requests: requests)
  handler(requests.eraseToAnyPublisher()).subscribe(clientStreamingSubscriber)
  return clientStreamingSubscriber.futureEventStreamProcessor
}

// MARK: Bidirectional Streaming

// TODO
