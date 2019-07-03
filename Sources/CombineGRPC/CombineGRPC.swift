import Combine
import GRPC
import SwiftProtobuf

public typealias UnaryRPC<A, B> = (A, CallOptions?) -> UnaryCall<A, B> where A: Message, B: Message

public func call<A, B>(_ rpc: @escaping UnaryRPC<A, B>) -> (A, CallOptions) -> UnaryCallPublisher<A, B> where A: Message, B: Message {
  return { request, callOptions in
    UnaryCallPublisher(rpc(request, callOptions))
  }
}

public func call<A, B>(_ rpc: @escaping UnaryRPC<A, B>) -> (A) -> UnaryCallPublisher<A, B> where A: Message, B: Message {
  return { request in
    UnaryCallPublisher(rpc(request, nil))
  }
}
