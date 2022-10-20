// Copyright 2019, ComgineGRPC
// Licensed under the Apache License, Version 2.0

import GRPC

extension RPCError {

  static func from(error: Error, statusCode: GRPCStatus.Code, message: String? = nil, cause: Error? = nil) -> RPCError {

    if let rpcError = error as? RPCError {
      return rpcError
    }

    return RPCError(status: .init(code: statusCode, message: message, cause: error))
  }

}
