// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "desktoppr",
    targets: [
        .executableTarget(
            name: "desktoppr",
            path: "desktoppr",
            exclude: [
                "Info.plist",
                "ToDo.markdown"
            ]
        ),
    ]
)
