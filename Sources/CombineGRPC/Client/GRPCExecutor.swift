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
  (CallOptions?, @escaping (Response) -> Void) -> BidirectionalStreamingCall<Request, Response>
  where Request: Message, Response: Message

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public struct GRPCExecutor {
  
  let retryPolicy: RetryPolicy
  
  let callOptions: CurrentValueSubject<CallOptions, Never>
  let retainedCallOptionsCancellable: Cancellable
  
  init(callOptions: AnyPublisher<CallOptions, Never> = Just(CallOptions()).eraseToAnyPublisher(),
       retry: RetryPolicy = .never) {
    self.retryPolicy = retry

    let subject = CurrentValueSubject<CallOptions, Never>(CallOptions())
    retainedCallOptionsCancellable = callOptions.sink(receiveValue: { subject.send($0) })
    self.callOptions = subject
  }
  
  // MARK:- Unary
  
  public func call<Request, Response>(_ rpc: @escaping UnaryRPC<Request, Response>)
    -> (Request)
    -> AnyPublisher<Response, GRPCStatus>
    where Request: Message, Response: Message
  {
    return { request in
      self.executeWithRetry(policy: self.retryPolicy, { callOptions in
        callOptions
          .flatMap { callOptions in
            Future<Response, GRPCStatus> { promise in
              let call = rpc(request, callOptions)
              call.response.whenSuccess { _ = promise(.success($0)) }
              call.status.whenSuccess { promise(.failure($0)) }
            }
          }
          .eraseToAnyPublisher()
      })
    }
  }
  
  // MARK: Server Streaming
  
  public func call<Request, Response>(_ rpc: @escaping ServerStreamingRPC<Request, Response>)
    -> (Request)
    -> AnyPublisher<Response, GRPCStatus>
    where Request: Message, Response: Message
  {
    return { request in
      self.executeWithRetry(policy: self.retryPolicy, { callOptions in
        callOptions
          .flatMap { callOptions -> ServerStreamingCallPublisher<Request, Response> in
            let bridge = MessageBridge<Response>()
            let call = rpc(request, callOptions, bridge.receive)
            return ServerStreamingCallPublisher(serverStreamingCall: call, messageBridge: bridge)
          }
          .eraseToAnyPublisher()
      })
    }
  }
  
  // MARK: Client Streaming
  
  public func call<Request, Response>(_ rpc: @escaping ClientStreamingRPC<Request, Response>)
    -> (AnyPublisher<Request, Error>)
    -> AnyPublisher<Response, GRPCStatus>
    where Request: Message, Response: Message
  {
    return { requests in
      self.executeWithRetry(policy: self.retryPolicy, { callOptions in
        callOptions
          .flatMap { callOptions -> Future<Response, GRPCStatus> in
            Future<Response, GRPCStatus> { promise in
              let call = rpc(callOptions)
              _ = requests.sink(
                receiveCompletion: { _ in _ = call.sendEnd() },
                receiveValue: { _ = call.sendMessage($0) }
              )
              call.response.whenSuccess { _ = promise(.success($0)) }
              call.status.whenSuccess { promise(.failure($0)) }
            }
          }
          .eraseToAnyPublisher()
      })
    }
  }
  
  // MARK: Bidirectional Streaming
  
  public func call<Request, Response>(_ rpc: @escaping BidirectionalStreamingRPC<Request, Response>)
    -> (AnyPublisher<Request, Error>)
    -> AnyPublisher<Response, GRPCStatus>
    where Request: Message, Response: Message
  {
    return { requests in
      self.executeWithRetry(policy: self.retryPolicy, { callOptions in
        callOptions
          .flatMap { callOptions -> BidirectionalStreamingCallPublisher<Request, Response> in
            let bridge = MessageBridge<Response>()
            let call = rpc(callOptions, bridge.receive)
            return BidirectionalStreamingCallPublisher(bidirectionalStreamingCall: call, messageBridge: bridge,
                                                       requests: requests)
          }
          .eraseToAnyPublisher()
      })
    }
  }
  
  // MARK: -
  
  private func executeWithRetry<T>(policy: RetryPolicy,
                                   _ call: @escaping (AnyPublisher<CallOptions, GRPCStatus>) -> AnyPublisher<T, GRPCStatus>)
    -> AnyPublisher<T, GRPCStatus>
  {
    switch policy {
    case .never:
      return call(currentCallOptions())
      
    case .failedCall(let maxRetries, let shouldRetry, let delayUntilNext, let onGiveUp):
      precondition(maxRetries >= 1, "RetryPolicy.failedCall upTo parameter should be at least 1")
      
      func attemptCall(retries: Int) -> AnyPublisher<T, GRPCStatus> {
        call(currentCallOptions())
          .catch { status -> AnyPublisher<T, GRPCStatus> in
            if shouldRetry(status) && retries < maxRetries {
              return delayUntilNext(retries)
                .setFailureType(to: GRPCStatus.self)
                .flatMap { _ in attemptCall(retries: retries + 1) }
                .eraseToAnyPublisher()
            }
            if shouldRetry(status) {
              onGiveUp()
            }
            return Fail(error: status).eraseToAnyPublisher()
          }
          .eraseToAnyPublisher()
      }
      
      return attemptCall(retries: 0)
    }
  }
  
  private func currentCallOptions() -> AnyPublisher<CallOptions, GRPCStatus> {
    self.callOptions
      .output(at: 0)
      .setFailureType(to: GRPCStatus.self)
      .eraseToAnyPublisher()
  }
}
