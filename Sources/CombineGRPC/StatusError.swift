//
//  StatusError.swift
//  CombineGRPC
//
//  Created by Vy-Shane Xie on 5/7/19.
//

import Foundation
import GRPC

public struct StatusError: Error {
  let code: GRPCStatus.Code
  let message: String?
  
  init(code: GRPCStatus.Code, message: String?) {
    self.code = code
    self.message = message
  }
}
