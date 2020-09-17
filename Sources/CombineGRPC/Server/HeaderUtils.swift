// Copyright 2020, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Foundation
import NIOHTTP1

func augment(headers: HTTPHeaders, withError: RPCError) -> HTTPHeaders {
  guard let errorHeaders = withError.trailingMetadata else {
    return headers
  }
  var augmented = HTTPHeaders()
  headers.forEach({ name, value in
    augmented.add(name: name, value: value)
  })
  errorHeaders.forEach({ name, value, _ in
    augmented.add(name: name, value: value)
  })
  return augmented
}
