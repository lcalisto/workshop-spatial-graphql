#!/bin/sh
# Fetch dargmuesli's codec-level typmod prototype (graphile/postgis PR #66 follow-up).
# Pinned to the commit verified on 2026-08-19; set REF=refs/heads/prototype/crystal-3109-codec-level-typmod for branch HEAD.
set -e
cd "$(dirname "$0")"
REF="${REF:-bd0e099adb802ba071b41c4151f396da3455fb3d}"
curl -fL -o prototype.tar.gz "https://codeload.github.com/dargmuesli/graphile-postgis/tar.gz/$REF"
rm -rf plugin-src
mkdir plugin-src
tar -xzf prototype.tar.gz -C plugin-src --strip-components=1
rm prototype.tar.gz
echo "OK: ./plugin-src ($REF)"
