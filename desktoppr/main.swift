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

let version = "0.1"

enum ScreenOption {
    case all
    case main
    case index(Int)
}

func usage() {
    errprint("""
desktoppr: a tool to set the desktop picture")
  usage: desktoppr [all|main|N] [/path/to/image]")
         all:        all screens (default)
         main:       main screen
         N: (number) screen index
         if a valid file path is given it will be set as the desktop picture,
         otherwise the path to the current desktop picture is printed
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

func parseURL(path : String) -> URL? {
    let fm = FileManager.default
    let cwd = URL(fileURLWithPath: fm.currentDirectoryPath)
    let url = URL(fileURLWithPath: path, relativeTo: cwd)
    if fm.fileExists(atPath: url.path) {
        return url
    } else {
        errprint("no file: \(path)")
        exit(1)
    }
    return nil
}

func desktopImagePath(for screen : NSScreen) -> String {
    let ws = NSWorkspace.shared
    return ws.desktopImageURL(for: screen)!.path
}

func setDesktopImage(url : URL, for screen : NSScreen) {
    let ws = NSWorkspace.shared
    try! ws.setDesktopImageURL(url, for: screen)
}

func main() {
    // first argument is always path to binary, ignore
    let arguments = CommandLine.arguments.dropFirst()
    
    var screenOption = ScreenOption.all
    var fileURL : URL?
    
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
        fileURL = parseURL(path: arguments[2])
    default:
        usage()
        exit(1)
    }
    
    if fileURL == nil {
        // display the desktop image path
        switch screenOption {
        case .all:
            for screen in NSScreen.screens {
                print(desktopImagePath(for: screen))
            }
        case .main:
            print(desktopImagePath(for: NSScreen.main!))
        case .index(let i):
            let screen = NSScreen.screens[i]
            print(desktopImagePath(for: screen))
        }
    } else {
        // set the desktop image
        switch screenOption {
        case .all:
            for screen in NSScreen.screens {
                setDesktopImage(url: fileURL!, for: screen)
            }
        case .main:
            setDesktopImage(url: fileURL!, for: NSScreen.main!)
        case .index(let i):
            let screen = NSScreen.screens[i]
            setDesktopImage(url: fileURL!, for: screen)
        }
    }
}

main()

