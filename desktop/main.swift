//
//  main.swift
//  desktop
//
//  Created by Armin Briegel on 2018-09-06.
//  Copyright © 2018 Scripting OS X. All rights reserved.
//

import Foundation
import AppKit

enum ScreenOption {
    case all
    case main
    case index(Int)
}

func usage() {
    errprint("""
desktop: a tool to set the desktop picture")
  usage: desktop [all|main|N] [/path/to/image]")
         all:        all screens (default)
         main:       main screen
         N: (number) screen index
         if a valid file path is given it will be set as the desktop picture,
         otherwise the path to the current desktop picture is printed
""")
}

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

func parseOption(_ arg: String) -> ScreenOption? {
    var option : ScreenOption?
    if arg == "all" {
        option = .all
    } else if arg == "main" {
        option = .main
    } else if let index = Int(arg) {
        if index < NSScreen.screens.count {
            option = .index(index)
        } else {
            errprint("No screen with index \(index)!")
            exit(1)
        }
    }
    return option
}

func parseFilePath(_ path : String) -> URL? {
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

func main() {
    let arguments = CommandLine.arguments
    
    var screenOption = ScreenOption.all
    var fileURL : URL?
    
    switch arguments.count {
    case 1:
        screenOption = ScreenOption.all
    case 2:
        if let option = parseOption(arguments[1]) {
            screenOption = option
        } else {
            fileURL = parseFilePath(arguments[1])
        }
    case 3:
        if let option = parseOption(arguments[1]) {
            screenOption = option
        } else {
            errprint("cannot parse \(arguments[1])")
            usage()
            exit(1)
        }
        fileURL = parseFilePath(arguments[2])
    default:
        usage()
        exit(1)
    }
    
    if fileURL == nil {
        // display the path
        let ws = NSWorkspace.shared
        switch screenOption {
        case .all:
            for screen in NSScreen.screens {
                print(ws.desktopImageURL(for: screen)!.path)
            }
        case .main:
            print(ws.desktopImageURL(for: NSScreen.main!)!.path)
        case .index(let i):
            let screen = NSScreen.screens[i]
            print(ws.desktopImageURL(for: screen)!.path)
        }
        
    } else {
        
    }
    
}

main()

