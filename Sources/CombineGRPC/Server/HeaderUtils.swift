// Copyright 2020, ComgineGRPC
// Licensed under the Apache License, Version 2.0

import Foundation
import NIOHPACK

func augment(headers: HPACKHeaders, with error: RPCError) -> HPACKHeaders {
  guard let errorHeaders = error.trailingMetadata else {
    return headers
  }
  var augmented = HPACKHeaders()
  augmented.add(contentsOf: headers)
  augmented.add(contentsOf: errorHeaders)
  return augmented
}
