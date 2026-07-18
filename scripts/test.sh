#!/bin/sh
# Runs `swift test` with the extra framework/rpath search paths the
# Swift Testing framework needs when only Xcode Command Line Tools (no
# full Xcode.app) are installed. If full Xcode is installed, plain
# `swift test` works fine and this script is unnecessary but harmless.
set -e

FRAMEWORKS="/Library/Developer/CommandLineTools/Library/Developer/Frameworks"
LIBDIR="/Library/Developer/CommandLineTools/Library/Developer/usr/lib"

cd "$(dirname "$0")/.."

swift test \
  -Xswiftc -F -Xswiftc "$FRAMEWORKS" \
  -Xlinker -rpath -Xlinker "$FRAMEWORKS" \
  -Xlinker -rpath -Xlinker "$LIBDIR" \
  "$@"
