// Copyright 2020, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Foundation
import Combine
import GRPC
import NIO

let host = "localhost"
let port = 30120

func makeTestServer(services: [CallHandlerProvider], eventLoopGroupSize: Int = 1) throws -> Server {
  let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: eventLoopGroupSize)
  return try Server
    .insecure(group: eventLoopGroup)
    .withServiceProviders(services)
    .bind(host: host, port: port)
    .wait()
}

func makeTestClient<Client>(_ clientCreator: (ClientConnection, CallOptions) -> Client)
  -> Client where Client: GRPCClient
{
  return makeTestClient(eventLoopGroupSize: 1, clientCreator)
}

func makeTestClient<Client>(eventLoopGroupSize: Int = 1, _ clientCreator: (ClientConnection, CallOptions) -> Client)
  -> Client where Client: GRPCClient
{
  let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
  let channel = ClientConnection
    .insecure(group: eventLoopGroup)
    .connect(host: host, port: port)
  let callOptions = CallOptions(timeLimit: TimeLimit.timeout(.milliseconds(200)))
  return clientCreator(channel, callOptions)
}
