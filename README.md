# iCanHazShortcut

Simple shortcut manager for macOS 13 or higher.
It lets you execute any command that works in your terminal by pressing a combination of keyboard keys.
No rocket science involved!

![iCanHazShortcut](https://d7.wtf/s/ichs.png)

## Installation

**Stable** release — download from the [Releases](https://github.com/deseven/icanhazshortcut/releases) page, or install via Homebrew:

```shell
brew install icanhazshortcut
```

**Dev** build — compiled from the `master` branch: [download](https://d7.wtf/s/ichs-dev.zip)  
*(only use this if you need unreleased functionality or want to help with testing)*

## AppleScript

- `list` / `listJSON` — list all shortcuts as TSV or JSON
- `enable` / `disable` / `toggle` / `trigger` — control a shortcut by its key combination (e.g. `"⇧⌘L"`)
- `enableAction` / `disableAction` / `toggleAction` / `triggerAction` — control a shortcut by its action name (e.g. `"lock screen"`)
- `enableID` / `disableID` / `toggleID` / `triggerID` — control a shortcut by its ID (e.g. `"a1b2c3d4e5"`)

> [!NOTE]
> Since v2.0.0, shortcut IDs are string-based (derived from action and command) and are **not compatible** with the numeric IDs used in v1.x.

Examples:

```applescript
tell application "iCanHazShortcut" to list
tell application "iCanHazShortcut" to enable "⇧⌘L"
tell application "iCanHazShortcut" to disableAction "lock screen"
tell application "iCanHazShortcut" to toggleID "a1b2c3d4e5"
tell application "iCanHazShortcut" to triggerAction "lock screen"
tell application "iCanHazShortcut" to listJSON
```

## Configuration

- Config is stored in TOML format at `~/Library/Application Support/iCanHazShortcut/ichs-config.toml`
- A backup is created automatically before every config change (up to 30 backups are kept in the `backups/` subdirectory)
- When upgrading from v1.x, the app will offer to migrate your old INI config (`~/.config/iCanHazShortcut/config.ini`) to the new format

## Building from Source

1. Install Xcode command line tools: `xcode-select --install`
2. Clone the repo
3. Run the build script:

```shell
./build.sh            # debug build (default)
./build.sh release    # release build with signing & notarization
```

For code signing and notarization, copy `.env.example` to `.env` and fill in the required variables.

## Help & Support

- [File an issue](https://github.com/deseven/icanhazshortcut/issues/new) for bugs, suggestions, or questions
- Reddit: https://www.reddit.com/r/iCanHazApps
- Telegram: https://t.me/icanhazshortcut
