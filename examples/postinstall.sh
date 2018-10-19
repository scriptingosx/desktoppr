#!/bin/bash

##
## sets the desktop using `desktoppr`
##


# set the path to the desktop image file here
picturepath="/Library/Desktop Pictures/BoringBlueDesktop.png"


# only run when installing on System Volume
if [[ $3 != "/" ]]; then
    echo "Not installing on /, not setting desktop"
    exit 0
fi

# verify the image exists
if [[ ! -f "$picturepath" ]]; then
    echo "no file at $picturepath, exiting"
    exit 1
fi

# verify that desktoppr is installed
desktoppr="/usr/local/bin/desktoppr"
if [[ ! -x "$desktoppr" ]]; then
    echo "cannot find desktoppr at $desktoppr, exiting"
    exit 1
fi

# get the current user
loggedInUser=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')

# test if a user is logged in
if [[ $loggedInUser != "" ]]; then
    # get the uid
    uid=$(id -u "$loggedInUser")
    # do what you need to do
    launchctl asuser "$uid" "$desktoppr" "$picturepath"
else
    echo "no user logged in, no desktop set"
fi
