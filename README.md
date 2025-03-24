# Here comes the `desktoppr`!

![](https://img.shields.io/github/v/release/scriptingosx/desktoppr)&nbsp;![](https://img.shields.io/github/downloads/scriptingosx/desktoppr/latest/total)&nbsp;![](https://img.shields.io/badge/macOS-10.13%2B-success)&nbsp;![](https://img.shields.io/github/license/scriptingosx/desktoppr)

A simple command line tool which can read and set the desktop picture/wallpaper. Credit for the name to [Neil Martin](https://macadmins.slack.com/archives/C19MR7EM9/p1536586211000100).

Note: Apple used to call the macOS background image 'desktop picture' until macOS 13 Ventura, when they changed to be the same as in iOS: 'wallpaper'. This documentation might use either term.

I have written a few blog posts that describe different use strategies for setting a desktop picture:

- [Using desktoppr in a managed environment](https://scriptingosx.com/2024/01/using-desktoppr-in-a-managed-environment/)
- [Building a LaunchD Installer pkg for desktoppr (and other tools)](https://scriptingosx.com/2024/07/building-a-launchd-installer-pkg-for-desktoppr-and-other-tools/)
- [Strategies to using desktoppr](https://scriptingosx.com/2020/03/strategies-to-using-desktoppr/)
- [Random Desktop Background with desktoppr](https://scriptingosx.com/2020/04/random-desktop-background-color-with-desktoppr/)

## Getting and setting the current desktop picture/wallpaper

You can read the current desktop picture/wallpaper with:

```
$ desktoppr
/Library/Desktop Pictures/Sierra.jpg
```

and set the desktop picture with

```
$ desktoppr "/Library/Desktop Pictures/BoringBlueDesktop.png"
```

**Note**: The new wallpaper will only be applied, when no app is using fullscreen mode while the `desktoppr` command is run ([See](https://github.com/scriptingosx/desktoppr/issues/17)).

When you have multiple displays, `desktoppr` will list all desktop pictures:

```
$ desktoppr
/Library/Desktop Pictures/HotStepper.jpg
/Library/Desktop Pictures/LyricalGangster.jpg
/Library/Desktop Pictures/MrOfficer.jpg
```

When you pass a file `desktoppr` will set it as the desktop picture for _all_ screens:

```
$ desktoppr /Library/Desktop Pictures/NaahNananah.jpg
$ desktoppr
/Library/Desktop Pictures/NaahNananah.jpg
/Library/Desktop Pictures/NaahNananah.jpg
/Library/Desktop Pictures/NaahNananah.jpg
```

You can also set the desktop for a specific screen: (index starts at zero)

```
$ desktoppr 0 /Library/Desktop Pictures/HotStepper.jpg
$ desktoppr 1 /Library/Desktop Pictures/LyricalGangster.jpg
$ desktoppr 2 /Library/Desktop Pictures/MrOfficer.jpg
```

`desktoppr` can also control the image scaling and background color for the desktop picture.

The scale and color settings will be set for all screens.

Use the `scale` verb to control how the desktops are scaled. It can have the values `fill` (default), `stretch`, `center`, or `fit`.

```
$ desktoppr scale center
```

You can pass a hex string for the background color:

```
$ desktoppr color 000000      # black background
$ desktoppr color FFFFFF      # white background
$ desktoppr color FF0000      # red background
```

Setting the wallpaper, scale and/or color are separate commands.

Note: setting the background color does not work in macOS 14.x. See [issue #22](https://github.com/scriptingosx/desktoppr/issues/22).

## Downloading the wallpaper image file

When you give a URL to an image file as the argument, `desktoppr` will download the file from the URL and set it as the wallpaper.

```
$ desktoppr https://raw.githubusercontent.com/scriptingosx/desktoppr/profile/examples/BoringBlueDesktop.png
```

The downloaded file will be stored in `~/Library/Application Support/desktoppr/`.

When the download fails, the wallpaper will not be changed. If the downloaded file is not an image file, the wallpaper will revert to the system default.

## desktoppr in scripts

When you want to run it from a script it is safest to include the entire path to the binary:

```
/usr/local/bin/desktoppr "/Library/Desktop Pictures/BoringBlueDesktop.png"
```

Since the `desktoppr` tool sets user preferences, you still need to pay attention that it runs as the user. A LaunchAgent or a solution like [`outset`](https://github.com/macadmins/outset) is a good choice to manage this. Alternatively, you can [run the command as the current user from a root script](https://scriptingosx.com/2020/08/running-a-command-as-another-user/).

## Managing the desktop picture/wallpaper with a profile

When you run `desktoppr` with the `manage` verb, it will read the settings from the `com.scriptingosx.desktoppr` preference domain. You can set these settings with the `defaults` command or, preferably, by pushing a configuration profile from an MDM server. 

The idea is to run `desktoppr manage` with a LaunchAgent plist at login and/or at regular intervals. You can find [a sample LaunchAgent plist here](examples/com.scriptingosx.desktopprmanage.plist). The sample LaunchAgent will run `desktoppr manage` at login and every three hours (10800 sec). You can build a pkg that installs the desktoppr binary, the LaunchAgent plist and an image file very early in the deployment workflow and then desktoppr sets the desktop background when the user reaches the desktop for the first time.

For Ventura and higher, binaries and applications run by LaunchAgents need to be approved with a `com.apple.servicemanagement` profile so they appear as managed in the login items section in Settings.app. The [sample configuration profile](examples/desktoppr-profile.mobileconfig) contains those settings, as well.


desktoppr uses the following keys:

#### `picture` (type: `string`)

The path to the image file for the desktop picture/wallpaper. The same image will be set for all screens.

When the value starts with `http://` or `https://` desktoppr will interpret this as a URL and attempt to download a file and set that file as the desktop picture/wallpaper. The downloaded file will be stored in `~/Library/Application Support/desktoppr/`. You can have desktoppr verify the downloaded image file by providing  a `sha256` checksum.

#### `sha256` (type: `string`)

This sha256 checksum will be used to verify the downloaded image file. If the checksum from the downloaded file does not match the value of this key, the desktop picture/wallpaper will not be changed.

You can generate the sha256 checksum of the image file with `shasum -a 256 <filepath>`

#### `color` (type: `string`)

This string will be interpreted as a six-digit hex code and set as the background color. (Note: setting the color [is broken on macOS 14.x](https://github.com/scriptingosx/desktoppr/issues/22).)

#### `scale` (type: `string`)

One of `fill` (default), `stretch`, `center`, or `fit`. This controls the scaling behavior of the image.

#### `setOnlyOnce` (type: boolean, default: `false`)

When set to `true`, `desktoppr manage` will not re-set the desktop picture/wallpaper if the last picture `desktoppr manage` set was the same. Use this to set the desktop image/wallpaper once from a configuration profile but allow the user to change it afterward. Even when `desktoppr manage` runs frequently, it should only re-set the desktop picture/wallpaper when the setting in the configuration profile changes.

When set to `false`, `desktoppr manage` will re-apply the managed settings every time.

The examples have [a sample defaults plist with keys](examples/defaults.plist) and [a sample configuration profile](examples/desktoppr-profile.mobileconfig).

## Download

You can get the code for `desktoppr` on my Github page and an installer in the [Releases](https://github.com/scriptingosx/desktoppr/releases). The installer pkg will install the binary in `/usr/local/bin`. Alternatively, a brew cask exists, so you could install it using `brew install --cask desktoppr` if you have [Homebrew](https://brew.sh) installed.

The tool requires the [Swift 5 Runtime support for command line tools](https://support.apple.com/kb/DL1998) when you install it on versions of macOS older than 10.14.4.

