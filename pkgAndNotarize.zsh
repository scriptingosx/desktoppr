#!/bin/zsh

#  pkgAndNotarize.sh
#  desktoppr
#
#  Created by Armin Briegel on 2023-11-21.
#  

# data from build settings
pkg_name="$PRODUCT_NAME"
identifier="$PRODUCT_BUNDLE_IDENTIFIER"
version=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$SRCROOT/desktoppr/Info.plist")
build_number=$(/usr/libexec/PlistBuddy -c "Print BuildNumber" "$SRCROOT/desktoppr/Info.plist")
min_os_version="$MACOSX_DEPLOYMENT_TARGET"

build_dir="$BUILD_DIR"
if [[ ! -d $build_dir ]]; then
    mkdir -p $build_dir
fi

artifacts_dir="$SRCROOT/build/Artifacts"
if [[ ! -d $artifacts_dir ]]; then
    mkdir -p $artifacts_dir
fi

logs_dir="$SRCROOT/build/Logs"
if [[ ! -d $logs_dir ]]; then
    mkdir -p $logs_dir
fi


component_path="${build_dir}/${pkg_name}.pkg"
product_path="${build_dir}/${pkg_name}-${version}-${build_number}.pkg"
notary_log="${build_dir}/pkg_build.log"

exec > >(tee -a "$notary_log") 2>&1

# Developer ID Installer cert name
#sign_cert="Developer ID Installer: Armin Briegel (JME5BW3F3R)"
sign_cert=$(security find-identity -p basic -v | awk '/Developer ID Installer/ && /'$DEVELOPMENT_TEAM'/ {print $2; exit}')

if [[ $sign_cert == "" ]]; then
  echo "error: could not find Developer ID Installer identity for $DEVELOPMENT_TEAM"
  exit 1
fi


echo "note: Packaging and Notarizing '$pkg_name', version: $version, build: $build_number"
date +"%F %T"
echo "note: Min OS Version:    $min_os_version"
echo "note: Development Team:  $DEVELOPMENT_TEAM"
echo "note: Installer cert ID: $sign_cert"
echo

# print environment variables
env | sort

echo

# set -x

# usually use `xcodebuild -exportArchive` to get
# the product out of the archive. However, this does not work
# with a command line tool, so we are going direct
# use INSTALL_ROOT when running with install
# use ARCHIVE_PATH after archiving
if [[ $ARCHIVE_PATH != "" ]]; then
  pkg_root="$ARCHIVE_PATH/Products/"
else
  pkg_root="$INSTALL_ROOT"
fi

#scripts_dir="$SRCROOT/Setup Manager/Package Resources/scripts"

# create the component pkg
echo "note: building component: $component_path"

if ! pkgbuild --root "$pkg_root" \
         --identifier "$identifier" \
         --version "$version-$build_number" \
         --install-location "/" \
         --min-os-version "$min_os_version" \
         --compression legacy \
         "$component_path"
then
  echo "error: error build component"
  exit 2
fi

echo

# create the distribution pkg
echo "note: building distribution pkg: $product_path"

if ! productbuild --package "$component_path" \
                  --identifier "$identifier" \
                  --version "$version-$build_number" \
                  --sign "$sign_cert" \
                  "$product_path"
then
  echo "error: error building distribution archive"
  exit 3
fi

echo

# clean up component pkg
rm "$component_path"

# only continue when development team is me
if [[ $DEVELOPMENT_TEAM != "JME5BW3F3R" ]]; then
  exit 0
fi

# profile name used with `notarytool --store-credentials`
credential_profile="notary-scriptingosx"

# notarize
echo "note: submitting for notarization"
xcrun notarytool submit "$product_path" \
                 --keychain-profile "$credential_profile" \
                 --wait

echo

# staple
xcrun stapler staple "$product_path"

# notify
osascript -e "display notification \"$pkg_name ($version, $build_number) built and notarized\""

# reveal in Finder
open -R "$product_path"

exit 0
