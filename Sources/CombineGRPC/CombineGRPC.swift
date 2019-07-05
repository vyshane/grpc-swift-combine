import Combine
import GRPC
import SwiftProtobuf

public typealias UnaryRPC<A, B> = (A, CallOptions?) -> UnaryCall<A, B>
  where A: Message, B: Message

public typealias ServerStreamingRPC<A, B> = (A, CallOptions?, @escaping (B) -> Void) -> ServerStreamingCall<A, B>
  where A: Message, B: Message

public typealias ClientStreamingRPC<A, B> = (CallOptions?) -> ClientStreamingCall<A, B>
  where A: Message, B: Message

public typealias BidirectionalStreamingRPC<A, B> = (CallOptions?, (B) -> Void) -> BidirectionalStreamingCall<A, B>
  where A: Message, B: Message


public func call<A, B>(_ rpc: @escaping UnaryRPC<A, B>)
  -> (A)
  -> UnaryCallPublisher<A, B>
  where A: Message, B: Message
{
  return { request in
    UnaryCallPublisher(unaryCall: rpc(request, nil))
  }
}

public func call<A, B>(_ rpc: @escaping UnaryRPC<A, B>)
  -> (A, CallOptions)
  -> UnaryCallPublisher<A, B>
  where A: Message, B: Message
{
  return { request, callOptions in
    UnaryCallPublisher(unaryCall: rpc(request, callOptions))
  }
}

public func call<A, B>(_ rpc: @escaping ServerStreamingRPC<A, B>)
  -> (A)
  -> ServerStreamingCallPublisher<A, B>
  where A: Message, B: Message
{
  return { request in
    let collector = ServerStreamingResponseCollector<B>()
    let call = rpc(request, nil, collector.receiver)
    return ServerStreamingCallPublisher(serverStreamingCall: call, responseCollector: collector)
  }
}

public func call<A, B>(_ rpc: @escaping ServerStreamingRPC<A, B>)
  -> (A, CallOptions)
  -> ServerStreamingCallPublisher<A, B>
  where A: Message, B: Message
{
  return { request, callOptions in
    let collector = ServerStreamingResponseCollector<B>()
    let call = rpc(request, callOptions, collector.receiver)
    return ServerStreamingCallPublisher(serverStreamingCall: call, responseCollector: collector)
  }
}