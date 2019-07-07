// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Combine
import GRPC
import SwiftProtobuf

public typealias UnaryRPC<Request, Response> =
  (Request, CallOptions?) -> UnaryCall<Request, Response>
  where Request: Message, Response: Message

public typealias ServerStreamingRPC<Request, Response> =
  (Request, CallOptions?, @escaping (Response) -> Void) -> ServerStreamingCall<Request, Response>
  where Request: Message, Response: Message

public typealias ClientStreamingRPC<Request, Response> =
  (CallOptions?) -> ClientStreamingCall<Request, Response>
  where Request: Message, Response: Message

public typealias BidirectionalStreamingRPC<Request, Response> =
  (CallOptions?, (Response) -> Void) -> BidirectionalStreamingCall<Request, Response>
  where Request: Message, Response: Message

// MARK: Unary

@available(OSX 10.15, *)
public func call<Request, Response>(_ rpc: @escaping UnaryRPC<Request, Response>)
  -> (Request)
  -> AnyPublisher<Response, StatusError>
  where Request: Message, Response: Message
{
  return { request in
    AnyPublisher(UnaryCallPublisher(unaryCall: rpc(request, nil)))
  }
}

@available(OSX 10.15, *)
public func call<Request, Response>(_ rpc: @escaping UnaryRPC<Request, Response>)
  -> (Request, CallOptions)
  -> AnyPublisher<Response, StatusError>
  where Request: Message, Response: Message
{
  return { request, callOptions in
    AnyPublisher(UnaryCallPublisher(unaryCall: rpc(request, callOptions)))
  }
}

// MARK: Server Streaming

@available(OSX 10.15, *)
public func call<Request, Response>(_ rpc: @escaping ServerStreamingRPC<Request, Response>)
  -> (Request)
  -> AnyPublisher<Response, StatusError>
  where Request: Message, Response: Message
{
  return { request in
    let bridge = MessageBridge<Response>()
    let call = rpc(request, nil, bridge.receive)
    return AnyPublisher(ServerStreamingCallPublisher(serverStreamingCall: call, messageBridge: bridge))
  }
}

@available(OSX 10.15, *)
public func call<Request, Response>(_ rpc: @escaping ServerStreamingRPC<Request, Response>)
  -> (Request, CallOptions)
  -> AnyPublisher<Response, StatusError>
  where Request: Message, Response: Message
{
  return { request, callOptions in
    let bridge = MessageBridge<Response>()
    let call = rpc(request, callOptions, bridge.receive)
    return AnyPublisher(ServerStreamingCallPublisher(serverStreamingCall: call, messageBridge: bridge))
  }
}

// MARK: Client Streaming

// TODO

// MARK: Bidirectional Streaming

// TODO
