// Copyright 2020, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Foundation
import GRPC
import NIOHPACK
import NIOHTTP1

/**
 Holds information about a failed gRPC call.
 */
public struct RPCError: Error, Equatable {
  public let status: GRPCStatus
  public let trailingMetadata: HPACKHeaders?
  
  public init(status: GRPCStatus) {
    self.init(status: status, trailingMetadata: nil)
  }
  
  public init(status: GRPCStatus, trailingMetadata: HTTPHeaders) {
    self.init(status: status, trailingMetadata: HPACKHeaders(httpHeaders: trailingMetadata))
  }
  
  public init(status: GRPCStatus, trailingMetadata: HPACKHeaders?) {
    self.status = status
    self.trailingMetadata = trailingMetadata
  }
}
