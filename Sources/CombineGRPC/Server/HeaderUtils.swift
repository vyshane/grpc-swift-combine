// Copyright 2020, Vy-Shane Xie
// Licensed under the Apache License, Version 2.0

import Foundation
import NIOHPACK

func augment(headers: HPACKHeaders, withError: RPCError) -> HPACKHeaders {
  guard let errorHeaders = withError.trailingMetadata else {
    return headers
  }
  var augmented = HPACKHeaders()
  augmented.add(contentsOf: headers)
  augmented.add(contentsOf: errorHeaders)
  return augmented
}
