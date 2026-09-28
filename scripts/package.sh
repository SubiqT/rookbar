#!/usr/bin/env bash
# Builds build/rookbar.app for VERSION and zips it as build/rookbar-VERSION-macos.zip.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
version="${1:?usage: package.sh VERSION}"

ROOKBAR_VERSION="$version" "$root/scripts/bundle.sh" >/dev/null
archive="$root/build/rookbar-$version-macos.zip"
rm -f "$archive"
ditto -c -k --sequesterRsrc --keepParent "$root/build/rookbar.app" "$archive"
echo "$archive"
