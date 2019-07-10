// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Combine
import GRPC
import SwiftProtobuf

// MARK: Unary

public typealias UnaryRPC<Request, Response> =
  (Request, CallOptions?) -> UnaryCall<Request, Response>
  where Request: Message, Response: Message

public func call<Request, Response>(_ rpc: @escaping UnaryRPC<Request, Response>)
  -> (Request)
  -> AnyPublisher<Response, GRPCStatus>
  where Request: Message, Response: Message
{
  return { request in
    UnaryCallPublisher(unaryCall: rpc(request, nil)).eraseToAnyPublisher()
  }
}

public func call<Request, Response>(_ rpc: @escaping UnaryRPC<Request, Response>)
  -> (Request, CallOptions)
  -> AnyPublisher<Response, GRPCStatus>
  where Request: Message, Response: Message
{
  return { request, callOptions in
    UnaryCallPublisher(unaryCall: rpc(request, callOptions)).eraseToAnyPublisher()
  }
}

// MARK: Server Streaming

public typealias ServerStreamingRPC<Request, Response> =
  (Request, CallOptions?, @escaping (Response) -> Void) -> ServerStreamingCall<Request, Response>
  where Request: Message, Response: Message

public func call<Request, Response>(_ rpc: @escaping ServerStreamingRPC<Request, Response>)
  -> (Request)
  -> AnyPublisher<Response, GRPCStatus>
  where Request: Message, Response: Message
{
  return { request in
    let bridge = MessageBridge<Response>()
    let call = rpc(request, nil, bridge.receive)
    return ServerStreamingCallPublisher(serverStreamingCall: call, messageBridge: bridge).eraseToAnyPublisher()
  }
}

public func call<Request, Response>(_ rpc: @escaping ServerStreamingRPC<Request, Response>)
  -> (Request, CallOptions)
  -> AnyPublisher<Response, GRPCStatus>
  where Request: Message, Response: Message
{
  return { request, callOptions in
    let bridge = MessageBridge<Response>()
    let call = rpc(request, callOptions, bridge.receive)
    return ServerStreamingCallPublisher(serverStreamingCall: call, messageBridge: bridge).eraseToAnyPublisher()
  }
}

// MARK: Client Streaming

public typealias ClientStreamingRPC<Request, Response> =
  (CallOptions?) -> ClientStreamingCall<Request, Response>
  where Request: Message, Response: Message

public func call<Request, Response>(_ rpc: @escaping ClientStreamingRPC<Request, Response>)
  -> (AnyPublisher<Request, Error>)
  -> AnyPublisher<Response, GRPCStatus>
  where Request: Message, Response: Message
{
  return { requests in
    let call = rpc(nil)
    return ClientStreamingCallPublisher(clientStreamingCall: call, requests: requests).eraseToAnyPublisher()
  }
}

public func call<Request, Response>(_ rpc: @escaping ClientStreamingRPC<Request, Response>)
  -> (AnyPublisher<Request, Error>, CallOptions?)
  -> AnyPublisher<Response, GRPCStatus>
  where Request: Message, Response: Message
{
  return { requests, callOptions in
    let call = rpc(callOptions)
    return ClientStreamingCallPublisher(clientStreamingCall: call, requests: requests).eraseToAnyPublisher()
  }
}

// MARK: Bidirectional Streaming

public typealias BidirectionalStreamingRPC<Request, Response> =
  (CallOptions?, @escaping (Response) -> Void) -> BidirectionalStreamingCall<Request, Response>
  where Request: Message, Response: Message

public func call<Request, Response>(_ rpc: @escaping BidirectionalStreamingRPC<Request, Response>)
  -> (AnyPublisher<Request, Error>)
  -> AnyPublisher<Response, GRPCStatus>
  where Request: Message, Response: Message
{
  return { requests in
    let bridge = MessageBridge<Response>()
    let call = rpc(nil, bridge.receive)
    return BidirectionalStreamingCallPublisher(bidirectionalStreamingCall: call, messageBridge: bridge,
                                               requests: requests).eraseToAnyPublisher()
  }
}

public func call<Request, Response>(_ rpc: @escaping BidirectionalStreamingRPC<Request, Response>)
  -> (AnyPublisher<Request, Error>, CallOptions?)
  -> AnyPublisher<Response, GRPCStatus>
  where Request: Message, Response: Message
{
  return { requests, callOptions in
    let bridge = MessageBridge<Response>()
    let call = rpc(callOptions, bridge.receive)
    return BidirectionalStreamingCallPublisher(bidirectionalStreamingCall: call, messageBridge: bridge,
                                               requests: requests).eraseToAnyPublisher()
  }
}
