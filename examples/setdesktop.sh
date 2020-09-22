#!/bin/sh

##
## sets the desktop using `desktoppr`
##

export PATH=/usr/bin:/bin:/usr/sbin:/sbin

# set the path to the desktop image file here
picturepath="/Library/Desktop Pictures/BoringBlueDesktop.png"


# verify the image exists
if [ ! -f "$picturepath" ]; then
    echo "no file at $picturepath, exiting"
    exit 1
fi

# verify that desktoppr is installed
desktoppr="/usr/local/bin/desktoppr"
if [ ! -x "$desktoppr" ]; then
    echo "cannot find desktoppr at $desktoppr, exiting"
    exit 1
fi

# get the current user
loggedInUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ && ! /loginwindow/ { print $3 }' )

# test if a user is logged in
if [ -n "$loggedInUser" ]; then
    # set the desktop for the user
    uid=$(id -u "$loggedInUser")
    launchctl asuser "$uid" sudo -u "$loggedInUser" "$desktoppr" "$picturepath"
else
    echo "no user logged in, no desktop set"
fi

