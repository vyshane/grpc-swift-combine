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

let connectionTarget = ConnectionTarget.hostAndPort("localhost", 30120)

func makeTestServer(services: [CallHandlerProvider], eventLoopGroupSize: Int = 1) throws -> EventLoopGroup {
  let eventLoopGroup = PlatformSupport.makeEventLoopGroup(loopCount: eventLoopGroupSize)
  let configuration = Server.Configuration(
    target: connectionTarget,
    eventLoopGroup: eventLoopGroup,
    serviceProviders: services
  )
  _ = try Server.start(configuration: configuration).wait()
  return eventLoopGroup
}

func makeTestClient<Client>(_ clientCreator: (ClientConnection, CallOptions) -> Client) -> Client
  where Client: GRPCServiceClient
{
  return makeTestClient(eventLoopGroupSize: 1, clientCreator)
}

func makeTestClient<Client>(eventLoopGroupSize: Int = 1, _ clientCreator: (ClientConnection, CallOptions) -> Client) -> Client
  where Client: GRPCServiceClient
{
  let eventLoopGroup = PlatformSupport.makeEventLoopGroup(loopCount: eventLoopGroupSize)
  let configuration = ClientConnection.Configuration(
    target: connectionTarget,
    eventLoopGroup: eventLoopGroup
  )
  let connection = ClientConnection(configuration: configuration)
  let callOptions = CallOptions(timeout: try! .milliseconds(200))
  return clientCreator(connection, callOptions)
}
