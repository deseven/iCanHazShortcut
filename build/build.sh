#!/bin/bash

pb="/Applications/PureBasic"
name="iCanHazShortcut"
ident="info.deseven.icanhazshortcut"
loc="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "$loc"
export PUREBASIC_HOME="$pb"
rm -rf "$loc/$name.app"

if [ -f "$pb/compilers/pbcompiler" ]; then
	"$pb/compilers/pbcompiler" -u -e "$loc/$name.app" "$loc/../main.pb"
	if [ -d "$loc/$name.app" ]; then
		cd ..
		build/inject.sh "$loc/$name.app"
		if [ ! -z "$1" ]; then
			# app signing
			codesign -f -s $1 "$loc/$name.app" -r="host => anchor apple and identifier com.apple.translate designated => identifier $ident"
		fi
	else
		echo "build failed"
	fi
else
	echo "can't find PB here: $pb"
fi
