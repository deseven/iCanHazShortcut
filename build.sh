#!/bin/bash

set -euo pipefail

name="iCanHazShortcut"
shortName="ichs"
ident="info.deseven.icanhazshortcut"
loc="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
logFile="$loc/build.log"
logMark=1

# Load .env if present
if [ -f "$loc/.env" ]; then
    set -a
    source "$loc/.env"
    set +a
fi

bold='\033[1m'
dimColor='\033[2m'
greenColor='\033[32m'
redColor='\033[31m'
noColor='\033[0m'

cd "$loc"

# ── Determine build mode ─────────────────────────────────────────────
mode="dev"
case "${1:-}" in
    dev-release) mode="dev-release" ;;
    release)     mode="release" ;;
    *)           mode="dev" ;;
esac

if [ "$mode" = "release" ]; then
    buildConfig="release"
else
    buildConfig="debug"
fi

# ── Determine signing & notarization ─────────────────────────────────
can_sign=false
can_notarize=false

if [ -n "${ICH_SIGNING_IDENTITY:-}" ] && [ "$mode" != "dev" ]; then
    can_sign=true
    if [ -n "${ICH_NOTARY_PROFILE:-}" ]; then
        can_notarize=true
    elif [ -n "${ICH_APPLE_ID:-}" ] && [ -n "${ICH_TEAM_ID:-}" ] && [ -n "${ICH_APP_PASSWORD:-}" ]; then
        can_notarize=true
    fi
fi

# ── Helpers ──────────────────────────────────────────────────────────

die() {
    echo -e "${redColor}[FAILED]${noColor}" > /dev/tty
    echo -e "  ${redColor}$1${noColor}" > /dev/tty
    echo -e "  ${dimColor}--- error output ---${noColor}" > /dev/tty
    tail -n +"$logMark" "$logFile" > /dev/tty 2>&1
    echo -e "  ${dimColor}--- end error output ---${noColor}" > /dev/tty
    exit 1
}

stepNum=0
totalSteps=0

step() {
    stepNum=$((stepNum + 1))
    printf "  ${dimColor}[%d/%d]${noColor} ${bold}%-36s${noColor} " "$stepNum" "$totalSteps" "$1"
}

ok() {
    echo -e "${greenColor}[OK]${noColor}"
}

run_step() {
    local label="$1"
    local error_msg="$2"
    shift 2
    local func="$1"
    shift

    step "$label"
    logMark=$(($(wc -l < "$logFile") + 1))
    {
        echo "--- $label ---"
        "$func" "$@" || die "$error_msg"
    } >> "$logFile" 2>&1
    ok
}

# ── Step functions ───────────────────────────────────────────────────

do_init_log() {
    echo "=== iCanHazShortcut build log ===" > "$logFile"
    echo "Date: $(date)" >> "$logFile"
    echo "Mode: $mode" >> "$logFile"
    echo "Signing: $can_sign" >> "$logFile"
    echo "Notarizing: $can_notarize" >> "$logFile"
    echo "" >> "$logFile"
}

do_clean_dist() {
    rm -rf "$loc/dist/$name.app"
    rm -rf "$loc/dist/$shortName.zip"
    rm -rf "$loc/dist/$shortName-dev.zip"
    rm -rf "$loc/dist/$shortName.dmg"
    rm -rf "$loc/dist/$name"
    mkdir -p "$loc/dist"
}

do_resolve_deps() {
    swift package resolve
}

do_clean_build() {
    swift package clean
}

do_compile_arm64() {
    swift build -c "$buildConfig" --arch arm64
}

do_compile_x86_64() {
    swift build -c "$buildConfig" --arch x86_64
}

do_create_universal() {
    lipo -create \
        "$loc/.build/arm64-apple-macosx/$buildConfig/$name" \
        "$loc/.build/x86_64-apple-macosx/$buildConfig/$name" \
        -output "$loc/dist/$name"
}

do_create_bundle() {
    mkdir -p "$loc/dist/$name.app/Contents/MacOS"
    mkdir -p "$loc/dist/$name.app/Contents/Resources"

    if [ "$mode" = "dev" ]; then
        cp "$loc/.build/arm64-apple-macosx/$buildConfig/$name" "$loc/dist/$name.app/Contents/MacOS/$name"
    else
        cp "$loc/dist/$name" "$loc/dist/$name.app/Contents/MacOS/$name"
        rm "$loc/dist/$name"
    fi

    cp "$loc/Info.plist" "$loc/dist/$name.app/Contents/Info.plist"
    cp "$loc/res/status_icon.png" "$loc/dist/$name.app/Contents/Resources/"
    cp "$loc/res/status_icon@2x.png" "$loc/dist/$name.app/Contents/Resources/"
    cp "$loc/res/main.icns" "$loc/dist/$name.app/Contents/Resources/"
    cp "$loc/res/AS.sdef" "$loc/dist/$name.app/Contents/Resources/"
    cp "$loc/LICENSE" "$loc/dist/$name.app/Contents/Resources/"
    cp "$loc/res/ui/"*.png "$loc/dist/$name.app/Contents/Resources/"
}

do_codesign() {
    xattr -cr "$loc/dist/$name.app"
    if [ "$can_sign" = true ]; then
        codesign --force --deep --sign "$ICH_SIGNING_IDENTITY" \
            --options runtime \
            --timestamp \
            "$loc/dist/$name.app"
    else
        codesign --force --deep --sign - \
            -r="designated => identifier \"$ident\"" \
            "$loc/dist/$name.app"
    fi
}

do_create_zip() {
    local zipName="$1"
    cd "$loc/dist"
    zip -r9 "$zipName" "$name.app"
    cd "$loc"
}

do_create_dmg() {
    local dmgStaging="$loc/dist/dmg_staging"
    rm -rf "$dmgStaging"
    mkdir -p "$dmgStaging"
    cp -R "$loc/dist/$name.app" "$dmgStaging/"
    create-dmg \
        --volname "$name" \
        --volicon "$loc/res/main.icns" \
        --background "$loc/res/dmg/bg.png" \
        --window-pos 200 120 \
        --window-size 640 520 \
        --icon-size 128 \
        --icon "$name.app" 192 350 \
        --app-drop-link 448 350 \
        "$loc/dist/$shortName.dmg" \
        "$dmgStaging"
    rm -rf "$dmgStaging"
}

do_sign_dmg() {
    codesign --force --sign "$ICH_SIGNING_IDENTITY" --timestamp "$loc/dist/$shortName.dmg"
}

do_notarize() {
    local file="$1"
    if [ -n "${ICH_NOTARY_PROFILE:-}" ]; then
        xcrun notarytool submit "$file" --keychain-profile "$ICH_NOTARY_PROFILE" --wait
    else
        xcrun notarytool submit "$file" \
            --apple-id "$ICH_APPLE_ID" \
            --team-id "$ICH_TEAM_ID" \
            --password "$ICH_APP_PASSWORD" \
            --wait
    fi
}

do_staple_app() {
    xcrun stapler staple "$loc/dist/$name.app"
}

do_staple_dmg() {
    xcrun stapler staple "$loc/dist/$shortName.dmg"
}

do_verify() {
    codesign --verify --deep --strict --verbose=2 "$loc/dist/$name.app"
    if [ "$can_notarize" = true ]; then
        xcrun stapler validate "$loc/dist/$name.app"
    fi
    if [ "$mode" = "release" ]; then
        spctl -a -vvv "$loc/dist/$shortName.dmg"
        if [ "$can_notarize" = true ]; then
            xcrun stapler validate "$loc/dist/$shortName.dmg"
        fi
    fi
}

do_upload() {
    share "$1"
}

# ── Calculate total steps per mode ───────────────────────────────────
case "$mode" in
    dev)         totalSteps=5 ;;
    dev-release)
        totalSteps=9
        if [ "$can_notarize" = true ]; then
            totalSteps=$((totalSteps + 2))
        fi
        if [ "$can_sign" = true ]; then
            totalSteps=$((totalSteps + 1))
        fi
        ;;
    release)
        totalSteps=9
        if [ "$can_sign" = true ]; then
            totalSteps=$((totalSteps + 1))
        fi
        if [ "$can_notarize" = true ]; then
            totalSteps=$((totalSteps + 3))
        fi
        if [ "$can_sign" = true ]; then
            totalSteps=$((totalSteps + 1))
        fi
        ;;
esac

# ── Build ────────────────────────────────────────────────────────────

do_init_log
do_clean_dist

run_step "Resolving dependencies..."            "failed to resolve dependencies"           do_resolve_deps
run_step "Cleaning build artifacts..."           "failed to clean build artifacts"          do_clean_build
run_step "Compiling Swift sources (arm64)..."    "failed to compile $shortName for arm64"   do_compile_arm64

if [ "$mode" != "dev" ]; then
    run_step "Compiling Swift sources (x86_64)..." "failed to compile $shortName for x86_64" do_compile_x86_64
    run_step "Creating universal binary..."        "failed to create universal binary"        do_create_universal
fi

run_step "Creating APP bundle..."                 "failed to create app bundle"              do_create_bundle
run_step "Code-signing APP bundle..."             "failed to code-sign app bundle"           do_codesign

if [ "$mode" != "dev" ]; then
    if [ "$mode" = "release" ]; then
        run_step "Creating distribution ZIP..."    "failed to pack $shortName.zip"            do_create_zip "$shortName.zip"
        run_step "Creating distribution DMG..."    "failed to create dmg"                     do_create_dmg
        if [ "$can_sign" = true ]; then
            run_step "Signing distribution DMG..." "failed to sign dmg"                       do_sign_dmg
        fi
        if [ "$can_notarize" = true ]; then
            run_step "Notarizing release build..." "failed to notarize release build"         do_notarize "$loc/dist/$shortName.dmg"
            run_step "Stapling APP bundle..."      "failed to staple app bundle"              do_staple_app
            run_step "Stapling release DMG..."     "failed to staple release DMG"             do_staple_dmg
        fi
        if [ "$can_sign" = true ]; then
            run_step "Verifying signatures..."     "failed to verify signatures"              do_verify
        fi
    else
        run_step "Creating dev ZIP..."             "failed to pack $shortName-dev.zip"        do_create_zip "$shortName-dev.zip"
        if [ "$can_notarize" = true ]; then
            run_step "Notarizing dev build..."     "failed to notarize dev build"             do_notarize "$loc/dist/$shortName-dev.zip"
            run_step "Stapling APP bundle..."      "failed to staple app bundle"              do_staple_app
        fi
        if [ "$can_sign" = true ]; then
            run_step "Verifying signatures..."     "failed to verify signatures"              do_verify
        fi
        run_step "Uploading dev build..."          "failed to upload dev build"               do_upload "$loc/dist/$shortName-dev.zip"
    fi
fi

# ── Post-build ───────────────────────────────────────────────────────
echo ""
echo -e "  ${greenColor}${bold}Build complete!${noColor}"

case "$mode" in
    dev)
        echo -e "  ${dimColor}mode: development${noColor}"
        echo -e "  ${dimColor}signing: ad-hoc${noColor}"
        echo -e "  ${dimColor}artifacts: dist/$name.app${noColor}"
        echo -e "  ${dimColor}launching...${noColor}"
        "$loc/dist/$name.app/Contents/MacOS/$name"
        ;;
    dev-release)
        echo -e "  ${dimColor}mode: development release${noColor}"
        echo -e "  ${dimColor}signing: $(if [ "$can_sign" = true ]; then echo "Developer ID"; else echo "ad-hoc"; fi)${noColor}"
        echo -e "  ${dimColor}notarized: $(if [ "$can_notarize" = true ]; then echo "yes"; else echo "no"; fi)${noColor}"
        echo -e "  ${dimColor}artifacts: dist/$name.app  dist/$shortName-dev.zip${noColor}"
        ;;
    release)
        echo -e "  ${dimColor}mode: release${noColor}"
        echo -e "  ${dimColor}signing: $(if [ "$can_sign" = true ]; then echo "Developer ID"; else echo "ad-hoc"; fi)${noColor}"
        echo -e "  ${dimColor}notarized: $(if [ "$can_notarize" = true ]; then echo "yes"; else echo "no"; fi)${noColor}"
        echo -e "  ${dimColor}artifacts: dist/$name.app  dist/$shortName.zip  dist/$shortName.dmg${noColor}"
        ;;
esac
