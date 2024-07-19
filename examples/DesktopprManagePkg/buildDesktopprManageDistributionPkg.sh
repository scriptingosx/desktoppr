#!/bin/sh

# template script to build a signed distribution pkg

# Permission is granted to use this code in any way you want.
# Credit would be nice, but not obligatory.
# Provided "as is", without warranty of any kind, express or implied.

export PATH=/usr/bin:/bin:/usr/sbin:/sbin

pkgname="DesktopprManage"
version="1.1"
identifier="com.scriptingosx.${pkgname}"
install_location="/"
minOSVersion="10.13"

# replace this with the name of your Developer ID _Installer_ certificate
# use `security find-identity -p codesigning -v` to list available certs
signature="Developer ID Installer: Armin Briegel (JME5BW3F3R)"


projectfolder=$(dirname "$0")
buildfolder="${projectfolder}/build"

if [ ! -e "$buildfolder" ]; then
    mkdir "$buildfolder"
fi

# build the component package
if ! pkgbuild --root "${projectfolder}/payload" \
              --identifier "${identifier}" \
              --version "${version}" \
              --ownership recommended \
              --install-location "${install_location}" \
              --scripts "${projectfolder}/scripts" \
              --min-os-version "${minOSVersion}" \
              --compression latest \
              "${buildfolder}/${pkgname}.pkg"
then
    returncode=$?
    echo "pkgbuild failed with return code $returncode"
    exit $returncode
fi

# build the distribution package
if ! productbuild --package "${buildfolder}/${pkgname}.pkg" \
                  --sign "${signature}" \
                  --identifier "${identifier}" \
                  --version "${version}" \
                  "${buildfolder}/${pkgname}-${version}.pkg"
then
    returncode=$?
    echo "productbuild failed with return code $returncode"
    exit $returncode
fi
    
# remove interim component package file
rm "${buildfolder}/${pkgname}.pkg"

# reveal the result in Finder
open -R "${buildfolder}/${pkgname}-${version}.pkg"
