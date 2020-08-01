//
//  TestUtils.swift
//  CombineGRPCTests
//
//  Created by Vy-Shane Xie on 12/7/19.
//

import Foundation
import Combine
import GRPC
import NIO

let host = "localhost"
let port = 30120

func makeTestServer(services: [CallHandlerProvider], eventLoopGroupSize: Int = 1) throws -> EventLoopGroup {
  let eventLoopGroup = PlatformSupport.makeEventLoopGroup(loopCount: eventLoopGroupSize)
  let configuration = Server.Configuration(
    target: ConnectionTarget.hostAndPort(host, port),
    eventLoopGroup: eventLoopGroup,
    serviceProviders: services
  )
  _ = try Server.start(configuration: configuration).wait()
  return eventLoopGroup
}

func makeTestClient<Client>(_ clientCreator: (ClientConnection, CallOptions) -> Client)
  -> Client where Client: GRPCClient
{
  return makeTestClient(eventLoopGroupSize: 1, clientCreator)
}

func makeTestClient<Client>(eventLoopGroupSize: Int = 1, _ clientCreator: (ClientConnection, CallOptions) -> Client)
  -> Client where Client: GRPCClient
{
  let eventLoopGroup = PlatformSupport.makeEventLoopGroup(loopCount: eventLoopGroupSize)
  let channel = ClientConnection
    .insecure(group: eventLoopGroup)
    .connect(host: host, port: port)
  let callOptions = CallOptions(timeLimit: TimeLimit.timeout(.milliseconds(200)))
  return clientCreator(channel, callOptions)
}
