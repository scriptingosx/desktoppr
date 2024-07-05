#  ToDo

- [ ] implement `resetAfterDate` logic
- [x] implement `scale` and `color` options in `manage`*
- [x] checksum for downloaded images
- [x] option to clear desktop to background color while downloading*
- [x] updated LaunchAgent plist to run on schedule as well
- [ ] add sample profile
- [ ] add sample profile with background item management
- [x] implement `respectUserChoice` logic: should only change when the current desktop is the default macOS image or the image previously set by desktoppr
- [ ] documentation for profile
- [ ] update readMe
- [ ] bring pkgAndNotarize workflow up to date
- [ ] create signed and notarized pkg with default LaunchAgent
- [ ] document how to build a customized launch agent
- [ ] create Installomator label for desktoppr with LaunchAgent

* broken in macOS 14 ([Issue #22](https://github.com/scriptingosx/desktoppr/issues/22)), FB13463850)
