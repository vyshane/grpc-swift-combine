import XCTest
import Combine
import GRPC
import NIO
import Foundation
@testable import CombineGRPC

@available(OSX 10.15, *)
final class CombineGRPCTests: XCTestCase {
  
  func wip() {
    let eventLoopGroup = GRPCNIO.makeEventLoopGroup(loopCount: 1)
    let configuration = ClientConnection.Configuration(
      target: .unixDomainSocket("/tmp/grpc-swift-combine.sock"),
      eventLoopGroup: eventLoopGroup
    )
    let connection = ClientConnection(configuration: configuration)
    let client = Grpcbin_GRPCBinServiceClient(connection: connection)
    
    let unaryCall = client.dummyUnary(Grpcbin_DummyMessage())
    
    UnaryCallPublisher(unaryCall).map { dummyMessage in
      //
    }
    
    call(client.dummyUnary)(Grpcbin_DummyMessage()).map { response in
      //
    }

    call(client.dummyUnary)(Grpcbin_DummyMessage(), CallOptions()).map { response in
      //
    }
    
//    stream(client.dummyServerStream)(Grpcbin_DummyMessage()).map { response in
//    }
  }

  static var allTests = [
    ("WIP", wip),
  ]
}
