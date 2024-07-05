//
//  Data-Checksums.swift
//  desktoppr
//
//  Created by Armin Briegel on 2024-01-04.
//  Copyright © 2024 Scripting OS X. All rights reserved.
//

import Foundation
import CryptoKit

@available(macOS 10.15, *)
extension Data {
  var md5: String {
    Insecure.MD5.hash(data: self).hexString
  }

  var sha1: String {
    Insecure.SHA1.hash(data: self).hexString
  }

  var sha256: String {
    CryptoKit.SHA256.hash(data: self).hexString
  }

  var sha384: String {
    CryptoKit.SHA384.hash(data: self).hexString
  }
  var sha512: String {
    CryptoKit.SHA512.hash(data: self).hexString
  }
}
