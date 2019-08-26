// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Combine
import GRPC
import SwiftProtobuf

// MARK: Unary

public typealias UnaryRPC<Request, Response> =
  (Request, CallOptions?) -> UnaryCall<Request, Response>
  where Request: Message, Response: Message

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public typealias ConfiguredUnaryRPC<Request, Response> =
  (@escaping UnaryRPC<Request, Response>)
  -> (Request)
  -> AnyPublisher<Response, GRPCStatus>
  where Request: Message, Response: Message

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public func call<Request, Response>(_ rpc: @escaping UnaryRPC<Request, Response>)
  -> (Request)
  -> AnyPublisher<Response, GRPCStatus>
  where Request: Message, Response: Message
{
  return { request in
    UnaryCallPublisher(unaryCall: rpc(request, nil)).eraseToAnyPublisher()
  }
}

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public func call<Request, Response>(_ callOptions: CallOptions)
  -> (@escaping UnaryRPC<Request, Response>)
  -> (Request)
  -> AnyPublisher<Response, GRPCStatus>
  where Request: Message, Response: Message
{
  return { rpc in
    return { request in
      UnaryCallPublisher(unaryCall: rpc(request, callOptions)).eraseToAnyPublisher()
    }
  }
}

// MARK: Server Streaming

public typealias ServerStreamingRPC<Request, Response> =
  (Request, CallOptions?, @escaping (Response) -> Void) -> ServerStreamingCall<Request, Response>
  where Request: Message, Response: Message

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public typealias ConfiguredServerStreamingRPC<Request, Response> =
  (@escaping ServerStreamingRPC<Request, Response>)
  -> (Request)
  -> AnyPublisher<Response, GRPCStatus>
  where Request: Message, Response: Message

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
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

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public func call<Request, Response>(_ callOptions: CallOptions)
  -> (@escaping ServerStreamingRPC<Request, Response>)
  -> (Request)
  -> AnyPublisher<Response, GRPCStatus>
  where Request: Message, Response: Message
{
  return { rpc in
    return { request in
      let bridge = MessageBridge<Response>()
      let call = rpc(request, callOptions, bridge.receive)
      return ServerStreamingCallPublisher(serverStreamingCall: call, messageBridge: bridge).eraseToAnyPublisher()
    }
  }
}

// MARK: Client Streaming

public typealias ClientStreamingRPC<Request, Response> =
  (CallOptions?) -> ClientStreamingCall<Request, Response>
  where Request: Message, Response: Message

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public typealias ConfiguredClientStreamingRPC<Request, Response> =
  (@escaping ClientStreamingRPC<Request, Response>)
  -> (AnyPublisher<Request, Error>)
  -> AnyPublisher<Response, GRPCStatus>
  where Request: Message, Response: Message

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
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

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public func call<Request, Response>(_ callOptions: CallOptions)
  -> (@escaping ClientStreamingRPC<Request, Response>)
  -> (AnyPublisher<Request, Error>)
  -> AnyPublisher<Response, GRPCStatus>
  where Request: Message, Response: Message
{
  return { rpc in
    return { requests in
      let call = rpc(callOptions)
      return ClientStreamingCallPublisher(clientStreamingCall: call, requests: requests).eraseToAnyPublisher()
    }
  }
}

// MARK: Bidirectional Streaming

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public typealias BidirectionalStreamingRPC<Request, Response> =
  (CallOptions?, @escaping (Response) -> Void) -> BidirectionalStreamingCall<Request, Response>
  where Request: Message, Response: Message

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public typealias ConfiguredBidirectionalStreamingRPC<Request, Response> =
  (@escaping BidirectionalStreamingRPC<Request, Response>)
  -> (AnyPublisher<Request, Error>)
  -> AnyPublisher<Response, GRPCStatus>
  where Request: Message, Response: Message

@available(macOS 10.15, iOS 13.0, *)
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

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public func call<Request, Response>(_ callOptions: CallOptions)
  -> (@escaping BidirectionalStreamingRPC<Request, Response>)
  -> (AnyPublisher<Request, Error>)
  -> AnyPublisher<Response, GRPCStatus>
  where Request: Message, Response: Message
{
  return { rpc in
    return { requests in
      let bridge = MessageBridge<Response>()
      let call = rpc(callOptions, bridge.receive)
      return BidirectionalStreamingCallPublisher(bidirectionalStreamingCall: call, messageBridge: bridge,
                                                 requests: requests).eraseToAnyPublisher()
    }
  }
}
