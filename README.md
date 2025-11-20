# SaneSideButtons
<p align="center">
	<img src="icon.png" width=150 />
</p>

macOS mostly ignores the M4/M5 mouse buttons, commonly used for navigation. Third-party apps can bind them to ⌘+[ and ⌘+], but this only works in a small number of apps and feels janky. With this tool, your side buttons will simulate 2-finger swipes, allowing you to navigate almost any window with a history. As seen in the Logitech MX Master!

## About SaneSideButtons

SaneSideButtons is a fork of the abandoned [SensibleSideButtons](https://github.com/archagon/sensible-side-buttons) by Alexei Baboulevitch. More information about SensibleSideButtons can be found on his [website](https://sensible-side-buttons.archagon.net/). Please consider using his [Amazon affiliate link](http://amzn.to/2tlwbAB) when making any purchase.

Starting with version 1.0.7 SaneSideButtons is maintained by [Jan Hülsmann](https://github.com/thealpa) and offers native Apple Silicon support.

## Installation

Download SaneSideButtons from [here](https://github.com/thealpa/SaneSideButtons/releases/latest/download/SaneSideButtons.dmg) or install using Homebrew:

```bash
brew install --cask sanesidebuttons
```

## Compatibility

- macOS Ventura (13.0) and above
- Intel and Apple Silicon (including M4 Macs)

## Building from Source

If you want to build SaneSideButtons from source or contribute to development:

1. Clone the repository
2. Run `./build_dmg.sh` to build and create a DMG
3. See [BUILD.md](BUILD.md) for detailed build instructions

Automated builds are available via GitHub Actions for every commit.

## Automatic launch
To launch SaneSideButtons automatically when you log in on your Mac:

1. Click the `System Preferences` icon in the Dock or choose Apple menu  > System Preferences.
1. Open the `General` preference pane.
1. Click on `Login Items` in the right preference pane.
1. Click on the plus button at the bottom of the `Open at Login` pane.
1. Navigate to your Applications folder (or wherever you put the app) and double-click `SaneSideButtons`.
