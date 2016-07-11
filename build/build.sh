#!/bin/bash

pb="/Applications/PureBasic"
name="iCanHazShortcut"
loc="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "$loc"
export PUREBASIC_HOME="$pb"
rm -rf "$loc/$name.app"

if [ -f "$pb/compilers/pbcompiler" ]; then
	"$pb/compilers/pbcompiler" -u -t -e "$loc/$name.app" "$loc/../main.pb"
	if [ -d "$loc/$name.app" ]; then
		cd ..
		build/inject.sh "$loc/$name.app"
	else
		echo "build failed"
	fi
else
	echo "can't find PB here: $pb"
fi
