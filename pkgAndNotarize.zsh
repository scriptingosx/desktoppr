#!/bin/zsh

signature="Developer ID Installer: Armin Briegel (JME5BW3F3R)"
dev_team="JME5BW3F3R" # asc-provider
dev_account="developer@scriptingosx.com"
dev_keychain_label="Developer-altool"

projectdir=$(dirname $0)

builddir="$projectdir/build"
pkgroot="$builddir/pkgroot"
infoplist="$projectdir/desktoppr/Info.plist"

plistbuddy="/usr/libexec/PlistBuddy"


# functions
requeststatus() { # $1: requestUUID
    requestUUID=${1?:"need a request UUID"}
    req_status=$(xcrun altool --notarization-info "$requestUUID" \
                          --username "$dev_account" \
                          --password "@keychain:$dev_keychain_label" 2>&1 | awk -F ': ' '/Status:/ { print $2; }' )
    echo "$req_status"
}

notarizefile() { # $1: path to file to notarize, $2: identifier
    filepath=${1:?"need a filepath"}
    identifier=${2:?"need an identifier"}
    
    # upload file
    echo "## uploading $filepath for notarization"
    requestUUID=$(xcrun altool --notarize-app \
                               --primary-bundle-id "$identifier" \
                               --username "$dev_account" \
                               --password "@keychain:$dev_keychain_label" \
                               --asc-provider "$dev_team" \
                               --file "$filepath" 2>&1 | awk '/RequestUUID/ { print $NF; }')
                               
    echo "Notarization RequestUUID: $requestUUID"
    
    if [[ $requestUUID == "" ]]; then 
        echo "could not upload for notarization"
        exit 1
    fi
        
    # wait for status to be not "in progress" any more
    request_status="in progress"
    while [[ "$request_status" == "in progress" ]]; do
        echo -n "waiting... "
        sleep 10
        request_status=$(requeststatus "$requestUUID")
        echo "$request_status"
    done
    
    if [[ $request_status != "success" ]]; then
        echo "## could not notarize $filepath"
        xcrun altool --notarization-info "$requestUUID" \
                     --username "$dev_account" \
                     --password "@keychain:$dev_keychain_label"
        exit 1
    fi
    
}


# build clean install

echo "## building with Xcode"
xcodebuild clean install -quiet

if [[ ! -d $pkgroot ]]; then
    echo "couldn't find pkgroot $pkgroot"
    exit 1
fi

# get project meta data
if [[ ! -r $infoplist ]]; then
    echo "cannot find Info.plist $infoplist"
fi

version=$($plistbuddy -c "print CFBundleVersion" "$infoplist")
identifier=$($plistbuddy -c "print CFBundleIdentifier" "$infoplist")
productname=$($plistbuddy -c "print CFBundleName" "$infoplist")

pkgpath="$builddir/$productname-$version.pkg"
componentpath="$builddir/$productname.pkg"

echo "## building pkg: $pkgpath"

pkgbuild --root "$pkgroot" \
         --version "$version" \
         --identifier "$identifier" \
         --sign "Developer ID Installer: Armin Briegel (JME5BW3F3R)" \
         "$componentpath"

productbuild --package "$componentpath" \
             --product "$builddir/requirements.plist" \
             --sign "Developer ID Installer: Armin Briegel (JME5BW3F3R)" \
             "$pkgpath"

# upload for notarization
notarizefile "$pkgpath" "$identifier"


# staple result
echo "## Stapling $pkgpath"
xcrun stapler staple "$pkgpath"

# also create a zip archive
zippath="$builddir/$productname-$version.zip"
zip "$zippath" -j "$pkgroot"/usr/local/bin/desktoppr

# upload zip for notarization
notarizefile "$zippath" "$identifier"

echo '## Done!'

exit 0


