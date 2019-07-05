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


public func call<Request, Response>(_ rpc: @escaping UnaryRPC<Request, Response>)
  -> (Request)
  -> UnaryCallPublisher<Request, Response>
  where Request: Message, Response: Message
{
  return { request in
    UnaryCallPublisher(unaryCall: rpc(request, nil))
  }
}

public func call<Request, Response>(_ rpc: @escaping UnaryRPC<Request, Response>)
  -> (Request, CallOptions)
  -> UnaryCallPublisher<Request, Response>
  where Request: Message, Response: Message
{
  return { request, callOptions in
    UnaryCallPublisher(unaryCall: rpc(request, callOptions))
  }
}

@available(OSX 10.15, *)
public func call<Request, Response>(_ rpc: @escaping ServerStreamingRPC<Request, Response>)
  -> (Request)
  -> ServerStreamingCallPublisher<Request, Response>
  where Request: Message, Response: Message
{
  return { request in
    let bridge = MessageBridge<Response>()
    let call = rpc(request, nil, bridge.receive)
    return ServerStreamingCallPublisher(serverStreamingCall: call, messageBridge: bridge)
  }
}

@available(OSX 10.15, *)
public func call<Request, Response>(_ rpc: @escaping ServerStreamingRPC<Request, Response>)
  -> (Request, CallOptions)
  -> ServerStreamingCallPublisher<Request, Response>
  where Request: Message, Response: Message
{
  return { request, callOptions in
    let bridge = MessageBridge<Response>()
    let call = rpc(request, callOptions, bridge.receive)
    return ServerStreamingCallPublisher(serverStreamingCall: call, messageBridge: bridge)
  }
}
