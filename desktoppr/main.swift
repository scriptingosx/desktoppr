//
//  main.swift
//  desktoppr
//

/*    Copyright 2018 Armin Briegel, Scripting OS X

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation
import AppKit
import CryptoKit

let version = "0.5"

enum ScreenOption : Equatable {
  case all
  case main
  case index(Int)
  case color
  case clip
  case scale
  case manage
}

enum ScaleOption : String {
  case fill
  case stretch
  case center
  case fit
}

func usage() {
  errprint("""
desktoppr: a tool to manage the desktop picture.

usage(1): desktoppr [all|main|N] [/path/to/image]
          all:   all screens (default)
          main:  main screen
          N:     screen index (number) 
          If a valid file path is given it will be set as the desktop picture,
          otherwise the path to the current desktop picture is printed.

usage(2): desktoppr color [hex-color-string]
          Gets the background color, or sets it if a hex color string (000000 to FFFFFF) is provided.
          Applies to _all_ screens.

usage(3): desktoppr scale [fill|stretch|center|fit]
          Gets the background image scaling, or sets it if a scaling value is provided.
          Applies to _all_ screens.
 
usage(4): desktoppr manage
          Read settings from com.scritpingosx.desktoppr preference domain.
          See documentation for details.

Source: https://github.com/scriptingosx/desktoppr
""")
}

// allows easy printing to stdErr
// from https://gist.github.com/algal/0a9aa5a4115d86d5cc1de7ea6d06bd91
extension FileHandle : TextOutputStream {
  public func write(_ string: String) {
    guard let data = string.data(using: .utf8) else { return }
    self.write(data)
  }
}

func errprint(_ error : String) {
  var standardError = FileHandle.standardError
  print(error, to:&standardError)
}

func parseOption(argument: String) -> ScreenOption? {
  var option : ScreenOption?
  switch argument {
  case "help":
    usage()
    exit(0)
  case "version":
    print(version)
    exit(0)
  case "all":
    option = .all
  case "main":
    option = .main
  case "color":
    option = .color
  case "clip":
    option = .clip
  case "scale":
    option = .scale
  case "manage":
    option = .manage
  default:
    // is the argument a number?
    if let index = Int(argument) {
      if index < NSScreen.screens.count {
        option = .index(index)
      } else {
        errprint("No screen with index \(index)!")
        exit(1)
      }
    }
  }
  return option
}

func download(from url: URL) -> String? {
//  var headRequest = URLRequest(url: url)
//  headRequest.httpMethod = "HEAD"
//  let headSemaphore = DispatchSemaphore(value: 0)
//  let headerTask = URLSession.shared.dataTask(with: headRequest) { _, response, error in
//    defer { headSemaphore.signal() }
//
//    if let httpResponse = response as? HTTPURLResponse {
//      print("http response code: \(httpResponse.statusCode)")
//      print("header fields: \(httpResponse.allHeaderFields)")
//    }
//    print(response?.suggestedFilename)
//  }
//  headerTask.resume()
//  headSemaphore.wait()

  let request = URLRequest(url: url)
  var newImage: URL? = nil
  let semaphore = DispatchSemaphore(value: 0)

  let downloadTask = URLSession.shared.downloadTask(with: request) { downloadedPicture, response, error in
    defer { semaphore.signal() }

    guard let downloadedPicture = downloadedPicture else { return }
    let filename = response?.suggestedFilename ?? downloadedPicture.lastPathComponent
    guard let applicationSupportDir = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else { return }
    let desktopprSupportDir = applicationSupportDir.appendingPathComponent("desktoppr", isDirectory: true)
    if !FileManager.default.fileExists(atPath: desktopprSupportDir.path) {
      do {
        try FileManager.default.createDirectory(at: desktopprSupportDir, withIntermediateDirectories: true, attributes: nil)
      } catch {
        return
      }
    }
    let newURL = desktopprSupportDir.appendingPathComponent(filename)
    do {
      if FileManager.default.fileExists(atPath: newURL.path) {
        try FileManager.default.removeItem(at: newURL)
      }
      try FileManager.default.moveItem(at: downloadedPicture, to: newURL)
    } catch {
      return
    }
    newImage = newURL
  }
  
  downloadTask.resume()
  semaphore.wait()
  return newImage?.path
}

func parseURL(path : String) -> URL? {
  let fm = FileManager.default
  var imagePath = path

  if path.starts(with: "http://") || path.starts(with: "https://") {
    if let url = URL(string: path),
       let downloadedImagePath = download(from: url) {
      imagePath = downloadedImagePath
      Defaults.lastURL = path
    } else {
      errprint("couldn't download: \(path)")
      exit(1)
    }
  }

  let cwd = URL(fileURLWithPath: fm.currentDirectoryPath)
  let url = URL(fileURLWithPath: imagePath, relativeTo: cwd)
  if fm.fileExists(atPath: url.path) {
    return url
  } else {
    errprint("no file: \(path)")
    exit(1)
  }
}

func colorFromHex(hexString : String) -> NSColor? {
  var result : NSColor? = nil

  if let colorCode = Int(hexString, radix: 16) {
    let redByte = (colorCode >> 16) & 0xff
    let greenByte = (colorCode >> 8) & 0xff
    let blueByte = colorCode & 0xff

    let redValue = CGFloat(redByte) / 0xff
    let greenValue = CGFloat(greenByte) / 0xff
    let blueValue = CGFloat(blueByte) / 0xff

    result = NSColor(calibratedRed: redValue, green: greenValue, blue: blueValue, alpha: 1.0)
  } else {
    errprint("could not parse color: \(hexString)")
    exit(1)
  }
  return result
}


func desktopImagePath(for screen : NSScreen) -> String {
  let ws = NSWorkspace.shared
  return ws.desktopImageURL(for: screen)!.path
}

func setAllDesktopImages(url: URL) {
  for screen in NSScreen.screens {
    setDesktopImage(url: url, for: screen)
  }

  Defaults.lastPath = url.path
  Defaults.lastSetDate = Date()
}

func setDesktopImage(url : URL, for screen : NSScreen) {
  let ws = NSWorkspace.shared
  try! ws.setDesktopImageURL(url, for: screen)
}

func setFillColor(color: NSColor) {
  let ws = NSWorkspace.shared
  // loop through all screens
  for screen in NSScreen.screens {
    let currentImageURL = ws.desktopImageURL(for: screen)
    var options = ws.desktopImageOptions(for: screen)
    options![NSWorkspace.DesktopImageOptionKey.fillColor] = color
    try! ws.setDesktopImageURL(currentImageURL!, for: screen, options: options!)
  }
}

func fillColor(for screen: NSScreen) -> String? {
  let ws = NSWorkspace.shared
  guard let options = ws.desktopImageOptions(for: screen) else { return nil }
  guard let fillColor = options[NSWorkspace.DesktopImageOptionKey.fillColor] as? NSColor else { return nil }

  let redByte = Int(fillColor.redComponent * 0xff)
  let greenByte = Int(fillColor.greenComponent * 0xff)
  let blueByte = Int(fillColor.blueComponent * 0xff)

  let hexString = String(format:"%02X%02X%02X", redByte, greenByte, blueByte)

  return hexString
}

// key never seems to be set in the image options
func allowClipping(for screen: NSScreen) -> Bool? {
  let ws = NSWorkspace.shared
  guard let options = ws.desktopImageOptions(for: screen) else { return nil }
  guard let clip = options[NSWorkspace.DesktopImageOptionKey.allowClipping] as? NSNumber else { return false }

  return clip.boolValue
}


// values map to the settings in Desktop pref pane as follwing:
// 0: (no value set in dict) Fill Screen
// 1: Stretch to Fill Screen
// 2: Center
// 3: Fit to Screen

func setImageScaling(_ scale: ScaleOption) {
  let ws = NSWorkspace.shared
  let scaleValue : NSNumber?
  switch scale {
  case .fill:
    scaleValue = nil
  case .stretch:
    scaleValue = NSNumber(integerLiteral: 1) // NSImageScaling.scaleAxesIndependently
  case .center:
    scaleValue = NSNumber(integerLiteral: 2) // NSImageScaling.scaleNone
  case .fit:
    scaleValue = NSNumber(integerLiteral: 3) // NSImageScaling.scaleProportionallyUpOrDown
  }

  // loop through all screens
  for screen in NSScreen.screens {
    let currentImageURL = ws.desktopImageURL(for: screen)
    let scalingKey = NSWorkspace.DesktopImageOptionKey.imageScaling
    var options = ws.desktopImageOptions(for: screen)
    if scaleValue == nil {
      options!.removeValue(forKey: scalingKey)
    } else {
      options![scalingKey] = scaleValue
    }
    try! ws.setDesktopImageURL(currentImageURL!, for: screen, options: options!)
  }
}


func imageScaling(for screen: NSScreen) -> ScaleOption? {
  let ws = NSWorkspace.shared
  guard let options = ws.desktopImageOptions(for: screen) else { return nil }
  let imageScalingValue = options[NSWorkspace.DesktopImageOptionKey.imageScaling] as? NSNumber
  var imageScaling : ScaleOption?
  if imageScalingValue == nil {
    imageScaling = .fill
  } else {
    switch imageScalingValue!.intValue {
    case 1:
      imageScaling = .stretch
    case 2:
      imageScaling = .center
    case 3:
      imageScaling = .fit
    default:
      imageScaling = nil
    }
  }
  return imageScaling
}

func main() {
  // first argument is always path to binary, ignore
  let arguments = CommandLine.arguments.dropFirst()

  var screenOption = ScreenOption.all
  var fileURL : URL?
  var color : NSColor?
  var scale : ScaleOption?

  switch arguments.count {
  case 0:
    screenOption = ScreenOption.all
  case 1:
    if let option = parseOption(argument: arguments[1]) {
      screenOption = option
    } else {
      fileURL = parseURL(path: arguments[1])
    }
  case 2:
    if let option = parseOption(argument: arguments[1]) {
      screenOption = option
    } else {
      errprint("cannot parse \(arguments[1])")
      usage()
      exit(1)
    }
    if screenOption == ScreenOption.color {
      if let parsedcolor = colorFromHex(hexString: arguments[2]) {
        color = parsedcolor
      }
    } else if screenOption == ScreenOption.scale {
      if let parsedScale = ScaleOption(rawValue: arguments[2]) {
        scale = parsedScale
      }
    } else {
      fileURL = parseURL(path: arguments[2])
    }
  default:
    usage()
    exit(1)
  }

  // display warning if running as root
  if ProcessInfo.processInfo.userName == "root" {
    errprint("desktoppr is running as root. This is probably not what you are intending. To set the desktop picture for a user, desktoppr needs to run as that user.")
  }

  switch screenOption {
  case .all:
    if fileURL == nil {
      for screen in NSScreen.screens {
        print(desktopImagePath(for: screen))
      }
    } else {
      setAllDesktopImages(url: fileURL!)
    }
  case .main:
    if fileURL == nil {
      print(desktopImagePath(for: NSScreen.main!))
    } else {
      setDesktopImage(url: fileURL!, for: NSScreen.main!)
    }
  case .index(let i):
    let screen = NSScreen.screens[i]
    if fileURL == nil {
      print(desktopImagePath(for: screen))
    } else {
      setDesktopImage(url: fileURL!, for: screen)
    }
  case .color:
    if color == nil {
      for screen in NSScreen.screens {
        print(fillColor(for: screen) ?? "cannot get color")
      }
    } else {
      setFillColor(color: color!)
    }
  case .clip:
    for screen in NSScreen.screens {
      print(allowClipping(for: screen)!.description)
    }
  case .scale:
    if scale == nil {
      for screen in NSScreen.screens {
        let s = imageScaling(for:screen)
        if s == nil {
          print("unkown")
        } else {
          print(s!.rawValue)
        }
      }
    } else {
      setImageScaling(scale!)
    }
  case .manage:
    setFromDefaults()
  }
}

func setFromDefaults() {
  if let picturePath = Defaults.picturePath {
    if let fileURL = parseURL(path: picturePath) {
      if #available(macOS 10.15, *) {
        // compare check sum when present
        if let sha256 = Defaults.sha256 {
          if sha256.lowercased() != fileURL.data?.sha256.lowercased() {
            errprint("sha256 checksum doesn't match")
            exit(9)
          }
        } else if let sha1 = Defaults.sha1 {
          if sha1.lowercased() != fileURL.data?.sha1.lowercased() {
            errprint("sha1 checksum doesn't match")
            exit(9)
          }
        } else if let md5 = Defaults.md5 {
          if md5.lowercased() != fileURL.data?.md5.lowercased() {
            errprint("md5 checksum doesn't match")
            exit(9)
          }
        }
      }


      if Defaults.setOnlyOnce {
        // check if we have set this path already
        // this allows the user to change the wallpaper without us overwriting it
        if Defaults.lastURL != Defaults.picturePath && Defaults.lastPath != Defaults.picturePath {

          if let colorString = Defaults.color,
             let color = colorFromHex(hexString: colorString) {
            setFillColor(color: color)
          }

          setImageScaling(Defaults.scale)

          setAllDesktopImages(url: fileURL)
        }
      } else {
        if let color = Defaults.color,
           let parsedColor = colorFromHex(hexString: color) {
          setFillColor(color: parsedColor)
        }

        setImageScaling(Defaults.scale)

        setAllDesktopImages(url: fileURL)
      }
    }
  }
}

main()

