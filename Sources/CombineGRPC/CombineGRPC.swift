// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Combine
import GRPC
import SwiftProtobuf

// MARK: Unary

public typealias UnaryRPC<Request, Response> =
  (Request, CallOptions?) -> UnaryCall<Request, Response>
  where Request: Message, Response: Message

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

public typealias ServerStreamingRPC<Request, Response> =
  (Request, CallOptions?, @escaping (Response) -> Void) -> ServerStreamingCall<Request, Response>
  where Request: Message, Response: Message

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

public typealias ClientStreamingRPC<Request, Response> =
  (CallOptions?) -> ClientStreamingCall<Request, Response>
  where Request: Message, Response: Message

@available(OSX 10.15, *)
public func call<Request, Response>(_ rpc: @escaping ClientStreamingRPC<Request, Response>)
  -> (AnyPublisher<Request, Error>)
  -> AnyPublisher<Response, StatusError>
  where Request: Message, Response: Message
{
  return { requests in
    let call = rpc(nil)
    return AnyPublisher(ClientStreamingCallPublisher(clientStreamingCall: call, requests: requests))
  }
}

@available(OSX 10.15, *)
public func call<Request, Response>(_ rpc: @escaping ClientStreamingRPC<Request, Response>)
  -> (AnyPublisher<Request, Error>, CallOptions?)
  -> AnyPublisher<Response, StatusError>
  where Request: Message, Response: Message
{
  return { requests, callOptions in
    let call = rpc(callOptions)
    return AnyPublisher(ClientStreamingCallPublisher(clientStreamingCall: call, requests: requests))
  }
}

// MARK: Bidirectional Streaming

public typealias BidirectionalStreamingRPC<Request, Response> =
  (CallOptions?, (Response) -> Void) -> BidirectionalStreamingCall<Request, Response>
  where Request: Message, Response: Message

// TODO
