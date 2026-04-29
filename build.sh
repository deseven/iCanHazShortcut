#!/bin/bash

set -euo pipefail

name="iCanHazShortcut"
shortName="ichs"
ident="info.deseven.icanhazshortcut"
loc="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
logFile="$loc/build.log"

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
    echo -e "${redColor}[FAILED]${noColor}"
    echo -e "  ${redColor}$1${noColor}"
    echo -e "  ${dimColor}check build.log for details${noColor}"
    exit 1
}

step() {
    printf "  ${dimColor}[%d/4]${noColor} ${bold}%s${noColor} " "$1" "$2"
}

ok() {
    echo -e "${greenColor}[OK]${noColor}"
}

# ── Compile ──────────────────────────────────────────────────────────
step 1 "Compiling swift sources..."
{
    echo "--- swiftc ---" >> "$logFile"
    swiftc \
        -target arm64-apple-macos11.0 \
        -framework Cocoa \
        -o "$loc/dist/$name" \
        "$loc/src/main.swift" \
        2>&1 >> "$logFile" \
        || die "failed to compile $shortName"
} >> "$logFile" 2>&1
ok

# ── Bundle ───────────────────────────────────────────────────────────
step 2 "Creating app bundle..."
{
    echo "--- app bundle ---" >> "$logFile"
    mkdir -p "$loc/dist/$name.app/Contents/MacOS"
    mkdir -p "$loc/dist/$name.app/Contents/Resources"

    cp "$loc/dist/$name" "$loc/dist/$name.app/Contents/MacOS/$name"
    cp "$loc/Info.plist" "$loc/dist/$name.app/Contents/Info.plist"
    cp "$loc/res/status_icon.png" "$loc/dist/$name.app/Contents/Resources/"
    cp "$loc/res/status_icon@2x.png" "$loc/dist/$name.app/Contents/Resources/"
    cp "$loc/res/main.icns" "$loc/dist/$name.app/Contents/Resources/"
    cp "$loc/res/AS.sdef" "$loc/dist/$name.app/Contents/Resources/"
    cp "$loc/res/ui/"*.png "$loc/dist/$name.app/Contents/Resources/"
} >> "$logFile" 2>&1
ok

# ── Zip ──────────────────────────────────────────────────────────────
step 3 "Packing into zip..."
{
    echo "--- zip ---" >> "$logFile"
    cd "$loc/dist"
    zip -r9 "$shortName.zip" "$name.app" 2>&1 >> "$logFile" || die "failed to pack $shortName"
    cd "$loc"
} >> "$logFile" 2>&1
ok

# ── DMG ──────────────────────────────────────────────────────────────
step 4 "Creating dmg..."
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
        --sandbox-safe \
        "$loc/dist/$shortName.dmg" \
        "$dmgStaging" \
        2>&1 >> "$logFile" \
        || die "failed to create dmg"
    rm -rf "$dmgStaging"
} >> "$logFile" 2>&1
ok

# clean up intermediate binary (keep only the .app, .zip and .dmg)
rm -f "$loc/dist/$name"

echo ""
echo -e "  ${greenColor}${bold}Build complete!${noColor}"
echo -e "  ${dimColor}artifacts: dist/$name.app  dist/$shortName.zip  dist/$shortName.dmg${noColor}"
