// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import XCTest
import Combine
import GRPC
import NIO
@testable import CombineGRPC

/**
 TODO
 */
@available(OSX 10.15, iOS 13, tvOS 13, *)
class StressTest: XCTestCase {

  static var serverEventLoopGroup: EventLoopGroup?
  static var unaryClient: UnaryScenariosClient?
  static var serverStreamingClient: ServerStreamingScenariosClient?
  static var clientStreamingClient: ClientStreamingScenariosClient?
  static var bidirectionalStreamingClient: BidirectionalStreamingScenariosClient?
  static var retainedCancellables: [AnyCancellable] = []
  
  override class func setUp() {
    super.setUp()

    let services: [CallHandlerProvider] = [
      UnaryTestsService(),
      ServerStreamingTestsService(),
      ClientStreamingTestsService(),
      BidirectionalStreamingTestsService()
    ]
    serverEventLoopGroup = try! makeTestServer(services: services, eventLoopGroupSize: 4)
    
    unaryClient = makeTestClient(eventLoopGroupSize: 4) { channel, callOptions in
      UnaryScenariosClient(channel: channel, defaultCallOptions: callOptions)
    }
    serverStreamingClient = makeTestClient(eventLoopGroupSize: 4) { channel, callOptions in
      ServerStreamingScenariosClient(channel: channel, defaultCallOptions: callOptions)
    }
    clientStreamingClient = makeTestClient(eventLoopGroupSize: 4) { channel, callOptions in
      ClientStreamingScenariosClient(channel: channel, defaultCallOptions: callOptions)
    }
    bidirectionalStreamingClient = makeTestClient(eventLoopGroupSize: 4) { channel, callOptions in
      BidirectionalStreamingScenariosClient(channel: channel, defaultCallOptions: callOptions)
    }
  }
  
  override class func tearDown() {
    try! unaryClient?.channel.close().wait()
    try! serverStreamingClient?.channel.close().wait()
    try! clientStreamingClient?.channel.close().wait()
    try! bidirectionalStreamingClient?.channel.close().wait()
    try! serverEventLoopGroup?.syncShutdownGracefully()
    retainedCancellables.removeAll()
    super.tearDown()
  }
  
  private func randomRequest() -> EchoRequest {
    let messageOfRandomSize = (0..<50).map { _ in UUID().uuidString }.reduce("", { $0 + $1 })
    return EchoRequest.with { $0.message = messageOfRandomSize }
  }
}
