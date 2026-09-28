# rookbar

A native yabai status bar for macOS, written in Swift with AppKit and SwiftUI.

rookbar shows yabai spaces on the left, the focused app in the centre, and layout mode,
caffeinate, volume, battery, network, date and time on the right. The focused-space accent is
matched to the wallpaper.

## Requirements

- macOS 14 or later
- [yabai](https://github.com/koekeishiya/yabai), with the scripting addition loaded for
  clicking a space to focus it
- An `external_bar` setting in `.yabairc` so windows leave room for the 32pt bar, for example
  `yabai -m config external_bar all:34:0`

## Install

```bash
make install                                         # builds and copies rookbar.app to /Applications
/Applications/rookbar.app/Contents/MacOS/rookbar --enable-service
```

To switch from jaybar, `scripts/replace-jaybar.sh` installs rookbar, disables jaybar's launch agent
and removes its yabai signals. `scripts/restore-jaybar.sh` switches back.

## Usage

```text
rookbar                         Start the status bar
rookbar --enable-service        Install and load the launch agent
rookbar --disable-service       Unload and remove the launch agent
rookbar --start-service         Start the launch agent
rookbar --stop-service          Stop the launch agent
rookbar --restart-service       Restart the launch agent
rookbar --render-preview [PATH] Render the bar with live data to a PNG
```

The launch agent restarts rookbar after a crash but not after Quit. Logs go to
`~/Library/Logs/rookbar.log`.

Each space shows its number and the apps on it as monochrome logos from
[sketchybar-app-font](https://github.com/kvndrsslr/sketchybar-app-font) (CC0). Apps the font does
not know get a generic glyph. The focused app in the centre uses the same logos. For full-colour
app icons instead, run `defaults write com.rookbar AppIconStyle colour` and restart rookbar.

Click a space to focus it, the cup to keep the display awake, and the network icon to show the
connection name. Showing the Wi-Fi network name needs Location Services permission; without it
rookbar shows "Wi-Fi".

## How it talks to yabai

rookbar queries yabai over its Unix socket instead of running the `yabai` binary. It registers
`rookbar_*` signals whose action is `notifyutil -p com.rookbar.yabai.changed`, so yabai never waits
on rookbar, and removes them on exit. A 1s poll picks up layout changes, which yabai does not
signal.

## Development

```bash
make build     # debug build
make test      # unit tests
make bundle    # build/rookbar.app
```
