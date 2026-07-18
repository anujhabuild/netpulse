#!/bin/sh
# Builds SpeedWidth in release mode and packages it into a proper
# SpeedWidth.app bundle (Contents/MacOS + Info.plist) so LSUIElement
# (no Dock icon) and SMAppService "Launch at Login" work correctly.
# `swift run` alone won't produce a real .app bundle.
set -e

cd "$(dirname "$0")/.."

swift build -c release

APP_DIR="build/SpeedWidth.app"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"

cp ".build/release/SpeedWidth" "$APP_DIR/Contents/MacOS/SpeedWidth"
cp "Sources/SpeedWidth/Info.plist" "$APP_DIR/Contents/Info.plist"

echo "Built $APP_DIR"
