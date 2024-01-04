//
//  Digest-Extension.swift
//  desktoppr
//
//  Created by Armin Briegel on 2024-01-04.
//  Copyright © 2024 Scripting OS X. All rights reserved.
//

import Foundation
import CryptoKit

@available(macOS 10.15, *)
extension Digest {
  var bytes: [UInt8] {
    Array(makeIterator())
  }

  var data: Data {
    Data(bytes)
  }

  var hexString: String {
    bytes.map { String(format: "%02x", $0) }.joined()
  }
}
