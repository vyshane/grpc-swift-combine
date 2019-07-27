# CombineGRPC

## Status

This project is a work in progress and should be considered experimental. It is based on the NIO implementation of Swift gRPC, currently at version 1.0.0-alpha.2, and integrates with Apple's new Combine framework, which is still in beta. Do not use this library in production.

## gRPC and Combine, Better Together

CombineGRPC is a library that provides [Combine framework](https://developer.apple.com/documentation/combine) integration for [gRPC Swift](https://github.com/grpc/grpc-swift). It provides two flavours of functions, `call` and `handle`. Use `call` to make gRPC calls on the client side, and `handle` to handle incoming RPC calls on the server side. CombineGRPC provides versions of `call` and `handle` for all RPC styles. Here are the input and output types for each.

RPC Style | Input and Output Types
--- | ---
| Unary | `Request -> AnyPublisher<Response, GRPCStatus>` |
| Server streaming | `Request -> AnyPublisher<Response, GRPCStatus>` |
| Client streaming | `AnyPublisher<Request, Error> -> AnyPublisher<Response, GRPCStatus>` |
| Bidirectional streaming | `AnyPublisher<Request, Error> -> AnyPublisher<Response, GRPCStatus>` |

When you make a unary call, you provide a request message, and get back a response publisher. The response publisher will either publish a single response, or fail with a `GRPCStatus` error. Similarly, if you are handling a unary RPC call, you provide a handler that takes a request parameter and returns an `AnyPublisher<Response, GRPCStatus>`.

You can follow the same intuition to understand the types for the other RPC styles. The only difference is that publishers for the streaming RPCs may publish zero or more messages instead of the single response message that is expected from the unary response publisher.

## Quick Tour

Let's see a quick example. Consider the following protobuf definition for a simple echo service. The service defines one bidirectional RPC. You send it a stream of messages and it echoes the messages back to you.

```protobuf
syntax = "proto3";

service EchoService {
  rpc SayItBack (stream EchoRequest) returns (stream EchoResponse);
}

message EchoRequest {
  string message = 1;
}

message EchoResponse {
  string message = 1;
}
```

To implement the server, you provide a handler function that takes an input stream `AnyPublisher<EchoRequest, Error>` and returns an output stream `AnyPublisher<EchoResponse, GRPCStatus>`.

```swift
class EchoServiceProvider: EchoProvider {
  
  // Simple bidirectional RPC that echoes back each request message
  func sayItBack(context: StreamingResponseCallContext<EchoResponse>) -> EventLoopFuture<(StreamEvent<EchoRequest>) -> Void> {
    handle(context) { requests in
      requests
        .map { req in
          EchoResponse.with { $0.message = req.message }
        }
        .mapError { _ in .processingError }
        .eraseToAnyPublisher()
    }
  }
}
```

On the client side, set up the gRPC client as you would using [Swift gRPC](https://github.com/grpc/grpc-swift). For example:

```swift
let configuration = ClientConnection.Configuration(
  target: ConnectionTarget.hostAndPort("localhost", 8080),
  eventLoopGroup: PlatformSupport.makeEventLoopGroup(loopCount: 1)
)
let echoClient = EchoServiceClient(connection: ClientConnection(configuration: configuration))
```

To call the service, use `call`. You provide it with a stream of requests `AnyPublisher<EchoRequest, Error>` and you get back a stream `AnyPublisher<EchoResponse, GRPCStatus>` of responses from the server.

```swift
let requests = repeatElement(EchoRequest.with { $0.message = "hello"}, count: 10)
let requestStream: AnyPublisher<EchoRequest, Error> =
  Publishers.Sequence(sequence: requests).eraseToAnyPublisher()

call(echoClient.sayItBack)(requestStream)
  .filter { $0.message == "hello" }
  .count()
  .sink(receiveValue: { count in
    assert(count == 10)
  })
```

That's it! You have set up bidirectional streaming between a server and client. The method `sayItBack` of `EchoServiceClient` is generated by Swift gRPC. Notice that `call` is curried. You can preconfigure RPC calls using partial application:

```swift
let sayItBack = call(echoClient.sayItBack)

sayItBack(requestStream).map { response in
  // ...
}
```

There is also a version of `call` that can partially apply `CallOptions`.

```swift
let options = CallOptions(timeout: try! .seconds(5))
let callWithTimeout: ConfiguredBidirectionalStreamingRPC<EchoRequest, EchoResponse> = call(options)

callWithTimeout(echoClient.sayItBack)(requestStream).map { response in
  // ...
}
```

It's handy for configuring authenticated calls.

```swift
let authenticatedCall: ConfiguredUnaryStreamingRPC<GetProfileRequest, Profile> =
  call(CallOptions(customMetadata: authenticationHeaders))

authenticatedCall(userClient.getProfile)(getProfileRequest).map { profile in
  // ...
}
```

### More Examples

Check out the [CombineGRPC tests](Tests/CombineGRPCTests) for examples of all the different RPC calls and handlers implementations. You can find the matching protobuf [here](Tests/Protobuf/test_scenarios.proto).

## Logistics

### Generating Swift Code from Protobuf

To generate Swift code from your .proto files, you'll need to first install the [protoc](https://github.com/protocolbuffers/protobuf) Protocol Buffer compiler and the [swift-protobuf](https://github.com/apple/swift-protobuf) plugin.

```text
brew install protobuf
brew install swift-protobuf
```

Next, download the latest version of grpc-swift with NIO support. Currently that means [gRPC Swift 1.0.0-alpha.2](https://github.com/grpc/grpc-swift/releases/tag/1.0.0-alpha.2). Unarchive the downloaded file and build the Swift gRPC plugin by running make in the root directory of the project.

```text
make plugin
```

Put the built binary somewhere in your $PATH. Now you are ready to generate Swift code from protobuf interface definition files.

Let's generate the message types, gRPC server and gRPC client for Swift.

```text
protoc example_service.proto --swift_out=Generated/
protoc example_service.proto --swiftgrpc_out=Generated/
```

You'll see that protoc has created two source files for us.

```text
ls Generated/
example_service.grpc.swift
example_service.pb.swift
```

### Adding CombineGRPC to Your Project

You can add CombineGRPC using Swift Package Manager by listing it as a dependency to your Package.swift configuration file.

```swift
dependencies: [
  .package(url: "https://github.com/vyshane/grpc-swift-combine.git", from: "0.1.1"),
],
```

## Compatibility

Since this library integrates with Combine, it only works on platforms that support Combine. This currently means the following minimum versions: macOS 10.15 Catalina, iOS 13, watchOS 6 and tvOS 13.

## To Do

RPC Client Calls

- [x] Unary
- [x] Client streaming
- [x] Server streaming
- [x] Bidirectional streaming

Server Side Handlers

- [x] Unary
- [x] Client streaming
- [x] Server streaming
- [x] Bidirectional streaming

End-to-end Tests

- [x] Unary
- [x] Client streaming
- [x] Server streaming
- [x] Bidirectional streaming
- [ ] Stress tests

Documentation

- [x] README.md
- [ ] Inline documentation using Markdown in comments
- [ ] Sample project

Maybe

- [ ] Automatic client call retries, e.g. to support ID token refresh on expire
