#!/bin/sh
# Builds NetPulse in release mode and packages it into a proper
# NetPulse.app bundle (Contents/MacOS + Info.plist) so LSUIElement
# (no Dock icon) and SMAppService "Launch at Login" work correctly.
# `swift run` alone won't produce a real .app bundle.
set -e

cd "$(dirname "$0")/.."

swift build -c release

APP_DIR="build/NetPulse.app"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"

cp ".build/release/NetPulse" "$APP_DIR/Contents/MacOS/NetPulse"
cp "Sources/NetPulse/Info.plist" "$APP_DIR/Contents/Info.plist"

echo "Built $APP_DIR"
