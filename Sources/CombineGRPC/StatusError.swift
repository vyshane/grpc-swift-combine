// Copyright 2019, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Foundation
import GRPC

public struct StatusError: Error {
  let code: GRPCStatus.Code
  let message: String?

  init(code: GRPCStatus.Code) {
    self.init(code: code, message: nil)
  }
  
  init(code: GRPCStatus.Code, message: String?) {
    self.code = code
    self.message = message
  }
}
