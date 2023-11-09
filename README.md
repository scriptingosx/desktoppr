# Here comes the `desktoppr`!

![](https://img.shields.io/github/v/release/scriptingosx/desktoppr)&nbsp;![](https://img.shields.io/github/downloads/scriptingosx/desktoppr/latest/total)&nbsp;![](https://img.shields.io/badge/macOS-10.12%2B-success)&nbsp;![](https://img.shields.io/github/license/scriptingosx/desktoppr)

I wrote a simple command line tool which can read and set the desktop picture. [Neil Martin had the brilliant idea](https://macadmins.slack.com/archives/C19MR7EM9/p1536586211000100) to call it `desktoppr`.

## Read the current desktop picture

```
$ desktoppr
/Library/Desktop Pictures/Sierra.jpg
```

## Set the desktop picture

```
$ desktoppr "/Library/Desktop Pictures/BoringBlueDesktop.png"
```

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

## Image scaling

Use the `scale` verb to control how the desktops are scaled. It can have the values `fill` (default), `stretch`, `center`, and `fit`.

```
desktoppr scale center
```

This will set the scale for _all_ screens.

## Background color

USe the `color` verb to set the background color. You can pass a hex string for the background color:

```
desktoppr color 000000      # black background
desktoppr color FFFFFF      # white background
desktoppr color FF0000      # red background
```

This will set the background color for _all_ screens.

# Source code

You can get the code for `desktoppr` on my Github page and an installer [here](https://github.com/scriptingosx/desktoppr/releases). The installer pkg will install the tool in `/usr/local/bin`. Alternatively, a brew casks exists, so you could install it using `brew install --cask desktoppr` if you have [Homebrew](https://brew.sh) installed.

When you want to run it from a management script it is safest to include the entire path:

```
/usr/local/bin/desktoppr "/Library/Desktop Pictures/BoringBlueDesktop.png"
```

Since the `desktoppr` tool also sets user preferences, you still need to pay attention that it runs as the user. A LaunchAgent or a solution like [`outset`](https://github.com/chilcote/outset) is a good choice to manage this. Alternatively, you can [run the command as the current user from a root script](https://scriptingosx.com/2020/08/running-a-command-as-another-user/).

The tool requires the [Swift 5 Runtime support for command line tools](https://support.apple.com/kb/DL1998) when you install it on versions of macOS older than 10.14.4.

I have written a few blog posts that describe different use strategies for setting a desktop picture:

- [Strategies to using desktoppr](https://scriptingosx.com/2020/03/strategies-to-using-desktoppr/)
- [Random Desktop Background with  desktoppr](https://scriptingosx.com/2020/04/random-desktop-background-color-with-desktoppr/)
