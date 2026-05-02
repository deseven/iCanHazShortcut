#!/bin/bash

set -euo pipefail

name="iCanHazShortcut"
shortName="ichs"
ident="info.deseven.icanhazshortcut"
loc="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
logFile="$loc/build.log"
logMark=1

bold='\033[1m'
dimColor='\033[2m'
greenColor='\033[32m'
redColor='\033[31m'
noColor='\033[0m'

cd "$loc"

# initialize build log
echo "=== iCanHazShortcut build log ===" > "$logFile"
echo "Date: $(date)" >> "$logFile"
echo "" >> "$logFile"

# clean previous artifacts
rm -rf "$loc/dist/$name.app"
rm -rf "$loc/dist/$shortName.zip"
rm -rf "$loc/dist/$shortName.dmg"
rm -rf "$loc/dist/$name"
mkdir -p "$loc/dist"

die() {
    echo -e "${redColor}[FAILED]${noColor}" > /dev/tty
    echo -e "  ${redColor}$1${noColor}" > /dev/tty
    echo -e "  ${dimColor}--- error output ---${noColor}" > /dev/tty
    tail -n +"$logMark" "$logFile" > /dev/tty 2>&1
    echo -e "  ${dimColor}--- end error output ---${noColor}" > /dev/tty
    exit 1
}

step() {
    printf "  ${dimColor}[%d/8]${noColor} ${bold}%-36s${noColor} " "$1" "$2"
}

ok() {
    echo -e "${greenColor}[OK]${noColor}"
}

# ── Resolve dependencies ─────────────────────────────────────────────
step 1 "Resolving dependencies..."
logMark=$(($(wc -l < "$logFile") + 1))
{
    echo "--- swift package resolve ---" >> "$logFile"
    swift package resolve 2>&1 >> "$logFile" || die "failed to resolve dependencies"
} >> "$logFile" 2>&1
ok

# ── Clean build artifacts ────────────────────────────────────────────
step 2 "Cleaning build artifacts..."
logMark=$(($(wc -l < "$logFile") + 1))
{
    echo "--- swift package clean ---" >> "$logFile"
    swift package clean 2>&1 >> "$logFile" || die "failed to clean build artifacts"
} >> "$logFile" 2>&1
ok

# ── Compile (arm64) ──────────────────────────────────────────────────
step 3 "Compiling Swift sources (arm64)..."
logMark=$(($(wc -l < "$logFile") + 1))
{
    echo "--- swift build --arch arm64 ---" >> "$logFile"
    swift build -c release --arch arm64 2>&1 >> "$logFile" || die "failed to compile $shortName for arm64"
} >> "$logFile" 2>&1
ok

# ── Compile (x86_64) ────────────────────────────────────────────────
step 4 "Compiling Swift sources (x86_64)..."
logMark=$(($(wc -l < "$logFile") + 1))
{
    echo "--- swift build --arch x86_64 ---" >> "$logFile"
    swift build -c release --arch x86_64 2>&1 >> "$logFile" || die "failed to compile $shortName for x86_64"
} >> "$logFile" 2>&1
ok

# ── Create universal binary ─────────────────────────────────────────
step 5 "Creating universal binary..."
logMark=$(($(wc -l < "$logFile") + 1))
{
    echo "--- lipo create ---" >> "$logFile"
    lipo -create \
        "$loc/.build/arm64-apple-macosx/release/$name" \
        "$loc/.build/x86_64-apple-macosx/release/$name" \
        -output "$loc/dist/$name" 2>&1 >> "$logFile" || die "failed to create universal binary"
} >> "$logFile" 2>&1
ok

# ── Bundle ───────────────────────────────────────────────────────────
step 6 "Creating APP bundle..."
logMark=$(($(wc -l < "$logFile") + 1))
{
    echo "--- app bundle ---" >> "$logFile"
    mkdir -p "$loc/dist/$name.app/Contents/MacOS"
    mkdir -p "$loc/dist/$name.app/Contents/Resources"

    cp "$loc/dist/$name" "$loc/dist/$name.app/Contents/MacOS/$name"
    rm "$loc/dist/$name"
    cp "$loc/Info.plist" "$loc/dist/$name.app/Contents/Info.plist"
    cp "$loc/res/status_icon.png" "$loc/dist/$name.app/Contents/Resources/"
    cp "$loc/res/status_icon@2x.png" "$loc/dist/$name.app/Contents/Resources/"
    cp "$loc/res/main.icns" "$loc/dist/$name.app/Contents/Resources/"
    cp "$loc/res/AS.sdef" "$loc/dist/$name.app/Contents/Resources/"
    cp "$loc/LICENSE" "$loc/dist/$name.app/Contents/Resources/"
    cp "$loc/res/ui/"*.png "$loc/dist/$name.app/Contents/Resources/"
} >> "$logFile" 2>&1
ok

# ── Zip ──────────────────────────────────────────────────────────────
step 7 "Creating distribution ZIP..."
logMark=$(($(wc -l < "$logFile") + 1))
{
    echo "--- zip ---" >> "$logFile"
    cd "$loc/dist"
    zip -r9 "$shortName.zip" "$name.app" 2>&1 >> "$logFile" || die "failed to pack $shortName"
    cd "$loc"
} >> "$logFile" 2>&1
ok

# ── DMG ──────────────────────────────────────────────────────────────
step 8 "Creating distribution DMG..."
logMark=$(($(wc -l < "$logFile") + 1))
{
    echo "--- create-dmg ---" >> "$logFile"
    dmgStaging="$loc/dist/dmg_staging"
    rm -rf "$dmgStaging"
    mkdir -p "$dmgStaging"
    cp -R "$loc/dist/$name.app" "$dmgStaging/"
    create-dmg \
        --volname "$name" \
        --volicon "$loc/res/main.icns" \
        --background "$loc/res/dmg/bg.png" \
        --window-pos 200 120 \
        --window-size 640 480 \
        --icon-size 128 \
        --icon "$name.app" 192 344 \
        --app-drop-link 448 344 \
        "$loc/dist/$shortName.dmg" \
        "$dmgStaging" \
        2>&1 >> "$logFile" \
        || die "failed to create dmg"
    rm -rf "$dmgStaging"
} >> "$logFile" 2>&1
ok

echo ""
echo -e "  ${greenColor}${bold}Build complete!${noColor}"
echo -e "  ${dimColor}artifacts: dist/$name.app  dist/$shortName.zip  dist/$shortName.dmg${noColor}"
