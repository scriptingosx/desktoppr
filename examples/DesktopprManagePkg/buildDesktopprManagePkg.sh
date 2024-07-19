#!/bin/sh

# template script to build a component pkg

# Permission is granted to use this code in any way you want.
# Credit would be nice, but not obligatory.
# Provided "as is", without warranty of any kind, express or implied.

export PATH=/usr/bin:/bin:/usr/sbin:/sbin

pkgname="DesktopprManage"
version="1.1"
identifier="com.scriptingosx.${pkgname}"
install_location="/"
minOSVersion="10.13"

# determine enclosing folder
projectfolder=$(dirname "$0")

# build the component package
pkgbuild --root "${projectfolder}/payload" \
         --identifier "${identifier}" \
         --version "${version}" \
         --ownership recommended \
         --install-location "${install_location}" \
         --scripts "${projectfolder}/scripts" \
         --min-os-version "${minOSVersion}" \
         --compression latest \
         "${pkgname}-${version}.pkg"
