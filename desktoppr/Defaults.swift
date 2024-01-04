//
//  Defaults.swift
//  desktoppr
//
//  Created by Armin Briegel on 2024-01-04.
//  Copyright © 2024 Scripting OS X. All rights reserved.
//

import Foundation

struct Defaults {
  static let defaults = UserDefaults.standard

  static let picturePathKey = "picture"
  static let colorKey = "color"
  static let scaleKey = "scale"
  static let setOnlyOnceKey = "setOnlyOnce"
  static let lastPathKey = "lastPath"
  static let lastURLKey = "lastURL"
  static let lastSetDateKey = "lastSetDate"
  static let respectUserChangeKey = "respectUserChange"
  static let md5Key = "md5"
  static let sha1Key = "sha1"
  static let sha256Key = "sha256"

  static var picturePath: String? {
    defaults.string(forKey: picturePathKey)
  }

  static var color: String? {
    defaults.string(forKey: colorKey)
  }

  static var scale: ScaleOption {
    guard let scale = defaults.string(forKey: scaleKey),
          let scaleOption = ScaleOption(rawValue: scale)
    else { return .fill }
    return scaleOption
  }

  static var setOnlyOnce: Bool {
    defaults.bool(forKey: setOnlyOnceKey)
  }

  static var lastPath: String? {
    get { defaults.string(forKey: lastPathKey) }
    set { defaults.set(newValue, forKey: lastPathKey) }
  }

  static var lastURL: String? {
    get { defaults.string(forKey: lastURLKey) }
    set { defaults.set(newValue, forKey: lastURLKey) }
  }

  static var lastSetDate: Date? {
    get { defaults.object(forKey: lastSetDateKey) as? Date }
    set { defaults.set(newValue, forKey: lastSetDateKey) }
  }

  static var respectUserChange: Bool {
    defaults.bool(forKey: respectUserChangeKey)
  }

  static var md5: String? {
    defaults.string(forKey: md5Key)
  }

  static var sha1: String? {
    defaults.string(forKey: sha1Key)
  }

  static var sha256: String? {
    defaults.string(forKey: sha256Key)
  }
}
