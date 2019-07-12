# CombineGRPC

> gRPC and Combine, better together.

CombineGRPC is a library that provides [Combine framework](https://developer.apple.com/documentation/combine) integration for [gRPC Swift](https://github.com/grpc/grpc-swift).

## Status

This project is a work in progress and should be considered experimental.

## Open Questions

### Future and Just

Investigate whether we can use [`Future`](https://developer.apple.com/documentation/combine/future) or [`Just`](https://developer.apple.com/documentation/combine/just) semantics for unary calls.

### CallOption via Partial Application

Consider supporting partial application for providing `CallOption` when making calls. E.g. use case:

```swift
let authenticatedCall = call(authCallOptions)
authenticatedCall(client.getProfile)(getProfileRequest).map { response in
  // ...
}
```
