# Building SaneSideButtons

This document describes how to build SaneSideButtons from source and create a distributable DMG file.

## ⚡ Don't Want to Install Xcode?

**Use GitHub Actions instead!** Every commit automatically builds DMG files in the cloud.

Run `./download_dmg.sh` for instructions, or go directly to:
- **View builds**: https://github.com/frankuyan/SaneSideButtons/actions
- **Download releases**: https://github.com/frankuyan/SaneSideButtons/releases

You can download pre-built DMG files without installing anything locally.

## Prerequisites (for Local Builds)

- macOS 13.0 (Ventura) or later
- **Xcode 15.0 or later** (Command Line Tools alone are NOT sufficient)
- Optional: `create-dmg` for prettier DMG files (`brew install create-dmg`)

> **Note**: Building .xcodeproj files requires full Xcode installation (16+ GB).
> If you don't want to install Xcode, use GitHub Actions (see above).

## Local Build (Manual)

### Quick Build

The easiest way to build and create a DMG is to use the provided build script:

```bash
./build_dmg.sh
```

This will:
1. Clean previous builds
2. Build the app using xcodebuild
3. Create a DMG file
4. Generate checksums

The output will be:
- `SaneSideButtons.dmg` - Latest build
- `SaneSideButtons-vX.X.X-buildNN.dmg` - Versioned build

### Manual Build Steps

If you prefer to build manually:

```bash
# 1. Build the app
xcodebuild \
  -project SaneSideButtons.xcodeproj \
  -scheme SaneSideButtons \
  -configuration Release \
  -derivedDataPath build \
  clean build

# 2. The app will be located at:
# build/Build/Products/Release/SaneSideButtons.app

# 3. Create DMG (using create-dmg)
create-dmg \
  --volname "SaneSideButtons" \
  --window-size 600 400 \
  --icon-size 100 \
  --app-drop-link 425 190 \
  "SaneSideButtons.dmg" \
  "build/Build/Products/Release/"

# Or create DMG (using hdiutil)
hdiutil create \
  -volname "SaneSideButtons" \
  -srcfolder "build/Build/Products/Release/SaneSideButtons.app" \
  -ov -format UDZO \
  "SaneSideButtons.dmg"
```

## Automated Builds (GitHub Actions)

This repository includes GitHub Actions workflows for automated building:

### Build on Push/PR

Every push to `main`, `master`, or `claude/*` branches triggers a build:
- Workflow: `.github/workflows/build.yml`
- Output: DMG files uploaded as artifacts (available for 30-90 days)
- Access: Go to Actions tab → Select workflow run → Download artifacts

### Release Builds

When you push a git tag starting with `v`, a release is automatically created:

```bash
# Create and push a tag
git tag v1.5.1
git push origin v1.5.1
```

This will:
- Build the app
- Create versioned DMG files
- Create a GitHub Release with:
  - DMG files attached
  - Checksums
  - Auto-generated release notes

Workflow: `.github/workflows/release.yml`

### Manual Workflow Trigger

You can also manually trigger builds from GitHub:
1. Go to Actions tab
2. Select "Build SaneSideButtons" or "Release"
3. Click "Run workflow"
4. Select branch and click "Run workflow"

## Development Build

For development and testing in Xcode:

1. Open `SaneSideButtons.xcodeproj` in Xcode
2. Select the `SaneSideButtons` scheme
3. Press `Cmd+B` to build
4. Press `Cmd+R` to run

## Code Signing

The build scripts create **unsigned** builds by default. For distribution:

1. **Development**: Unsigned builds work fine for personal use
2. **Distribution**: You'll need to:
   - Sign with your Apple Developer certificate
   - Notarize the app with Apple
   - Update workflows to use signing credentials

To enable signing in the workflow, you'll need to:
- Add your certificate and provisioning profile to GitHub Secrets
- Modify the build commands to use proper code signing
- Add notarization steps

## Troubleshooting

### Build fails with "xcodebuild: command not found"
- Install Xcode from the Mac App Store
- Run: `sudo xcode-select --install`

### DMG creation fails
- Install create-dmg: `brew install create-dmg`
- Or the script will fall back to hdiutil automatically

### Permission denied when running build_dmg.sh
- Make it executable: `chmod +x build_dmg.sh`

### Build succeeds but app won't open
- The app requires Accessibility permissions
- Unsigned apps may need to be opened via right-click → Open

## Build Configuration

The app is configured in `SaneSideButtons.xcodeproj/project.pbxproj`:
- Deployment target: macOS 15.0
- Swift version: 6.0
- Marketing version: 1.5.0
- Build number: 26

## Clean Build

To completely clean all build artifacts:

```bash
rm -rf build/ *.dmg dmg_temp/ DerivedData/
xcodebuild clean -project SaneSideButtons.xcodeproj -scheme SaneSideButtons
```
