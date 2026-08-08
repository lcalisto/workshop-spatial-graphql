#!/bin/sh
# Fetch the @graphile/postgis v5 source from PR #66 (dargmuesli/graphile-postgis).
# Run this once before docker compose build; the Dockerfile expects the
# ./graphile-postgis-fzy-v5-dargmuesli/ directory in the build context.
#
# Pinned to the commit verified on 2026-08-08.
# For the branch HEAD instead: REF=refs/heads/fzy/v5/dargmuesli ./get-pr66-src.sh
set -e
cd "$(dirname "$0")"
REF="${REF:-b65f53f3de1e9c570fd1a99297acf0f39a6d07fd}"
curl -fL -o pr66-src.tar.gz "https://codeload.github.com/dargmuesli/graphile-postgis/tar.gz/$REF"
rm -rf graphile-postgis-fzy-v5-dargmuesli
mkdir graphile-postgis-fzy-v5-dargmuesli
tar -xzf pr66-src.tar.gz -C graphile-postgis-fzy-v5-dargmuesli --strip-components=1
rm pr66-src.tar.gz
echo "OK: ./graphile-postgis-fzy-v5-dargmuesli ($REF)"
