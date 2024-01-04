//
//  URL-Data.swift
//  desktoppr
//
//  Created by Armin Briegel on 2024-01-04.
//  Copyright © 2024 Scripting OS X. All rights reserved.
//

import Foundation

extension URL {
  var data: Data? {
    try? Data(contentsOf: self)
  }
}
