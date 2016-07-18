#!/bin/bash

pb="/Applications/PureBasic"
name="iCanHazShortcut"
shortName="ichs"
ident="info.deseven.icanhazshortcut"
loc="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

noColor='\033[0m'
greenColor='\033[32m'
redColor='\033[31m'

cd "$loc"
export PUREBASIC_HOME="$pb"
rm -rf "$loc/$name.app"
rm -rf "$loc/$shortName.zip"

die() {
	echo -e $redColor"\n$1"$noColor
	exit 1
}

if [ -f "$pb/compilers/pbcompiler" ]; then
	echo -ne $greenColor"compiling $shortName..."$noColor
	"$pb/compilers/pbcompiler" -u -e "$loc/$name.app" "$loc/../main.pb" > /dev/null || die "failed to build $shortName"
	if [ -d "$loc/$name.app" ]; then
		echo -ne $greenColor"\ninjecting resources..."$noColor
		cd ..
		build/inject.sh "$loc/$name.app" || die "failed to inject $shortName"
		echo -ne $greenColor"\nsigning bundle..."$noColor
		if [ ! -z "$1" ]; then
			# app signing
			codesign -f -s $1 "$loc/$name.app" -r="host => anchor apple and identifier com.apple.translate designated => identifier $ident" > /dev/null || die "failed to sign $shortName"
		fi
		echo -ne $greenColor"\npacking distro..."$noColor
		cd "$loc"
		zip -r9 "$shortName.zip" "$name.app" > /dev/null || die "failed to pack $shortName"
		echo
	else
		die "bundle not found"
	fi
else
	die "can't find PB here: $pb"
fi
