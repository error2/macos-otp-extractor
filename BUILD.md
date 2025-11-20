# Build Instructions for OTP Extractor

## Prerequisites

- macOS 13.0 (Ventura) or later
- Xcode 14.0 or later
- Command Line Tools installed: `xcode-select --install`

## Initial Setup (First Time Only)

Since there's no `.xcodeproj` file yet, you need to create the Xcode project:

### Option 1: Create Project in Xcode (Recommended)

1. **Open Xcode**
2. **File > New > Project**
3. Choose **macOS > App**
4. Configure:
   - Product Name: `OTPExtractor`
   - Team: Your Apple Developer Team
   - Organization Identifier: `com.error` (or your own)
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Use Core Data: **NO**
   - Include Tests: **Optional**

5. **Save in the project directory** (`macos-otp-extractor`)

6. **Delete the auto-generated files:**
   - Delete `ContentView.swift` (if created)
   - Delete the default app file if it conflicts

7. **Add existing files to the project:**
   - Drag all `.swift` files into the project:
     - `OTPExtractorApp.swift`
     - `Constants.swift`
     - `ClipboardManager.swift`
     - `PreferencesManager.swift`
     - `PreferencesWindow.swift`
   - Add `Assets.xcassets`
   - Add `OTPExtractor.entitlements`

8. **Add SQLite.swift Package:**
   - File > Add Package Dependencies
   - Enter URL: `https://github.com/stephencelis/SQLite.swift.git`
   - Version: Up to Next Major (recommended)
   - Add to target: `OTPExtractor`

9. **Configure Build Settings:**
   - Select project in navigator
   - Go to "Signing & Capabilities"
   - Select your Team
   - Ensure "App Sandbox" is set correctly (should be disabled for Full Disk Access)
   - Add entitlements file: `OTPExtractor.entitlements`

10. **Build the app:**
    ```bash
    ⌘B or Product > Build
    ```

### Option 2: Create Using Swift Package (Advanced)

Create a `Package.swift` file:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OTPExtractor",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.15.0")
    ],
    targets: [
        .executableTarget(
            name: "OTPExtractor",
            dependencies: [
                .product(name: "SQLite", package: "SQLite.swift")
            ],
            path: ".",
            sources: [
                "OTPExtractorApp.swift",
                "Constants.swift",
                "ClipboardManager.swift",
                "PreferencesManager.swift",
                "PreferencesWindow.swift"
            ]
        )
    ]
)
```

Then build with:
```bash
swift build -c release
```

**Note:** This creates a command-line executable, not a proper .app bundle. Option 1 is recommended for menu bar apps.

## Building from Command Line

Once the Xcode project is set up:

```bash
# Clean build folder
xcodebuild clean -project OTPExtractor.xcodeproj -scheme OTPExtractor

# Build for release
xcodebuild -project OTPExtractor.xcodeproj \
           -scheme OTPExtractor \
           -configuration Release \
           -derivedDataPath build \
           build

# The .app will be in:
# build/Build/Products/Release/OTPExtractor.app
```

## Code Signing

For distribution, you need to sign the app:

```bash
# Sign the app
codesign --force --deep --sign "Developer ID Application: Your Name" \
         build/Build/Products/Release/OTPExtractor.app

# Verify signature
codesign --verify --deep --strict --verbose=2 \
         build/Build/Products/Release/OTPExtractor.app

# Check entitlements
codesign -d --entitlements - build/Build/Products/Release/OTPExtractor.app
```

## Creating a DMG for Distribution

```bash
# Create a DMG
hdiutil create -volname "OTP Extractor" \
               -srcfolder build/Build/Products/Release/OTPExtractor.app \
               -ov -format UDZO \
               OTPExtractor.dmg
```

## Troubleshooting

### Build Errors

1. **"Cannot find 'Connection' in scope"**
   - Solution: Make sure SQLite.swift package is added

2. **"No such module 'SQLite'"**
   - Solution: Clean build folder and rebuild

3. **Code signing issues**
   - Solution: Set your Team in Signing & Capabilities

### Runtime Issues

1. **App crashes on launch**
   - Check Console.app for crash logs
   - Verify all .swift files are included in target

2. **Can't read Messages database**
   - Grant Full Disk Access in System Settings
   - Restart the app after granting permission

## Testing

After building:

1. Copy app to `/Applications/`
2. Grant Full Disk Access:
   - System Settings > Privacy & Security > Full Disk Access
   - Add OTPExtractor.app
3. Launch the app
4. Check menu bar for key icon
5. Test with a verification code message

## Distribution Checklist

- [ ] Code is signed with Developer ID
- [ ] App is notarized by Apple (for public distribution)
- [ ] DMG created and tested
- [ ] README updated with download link
- [ ] GitHub release created with:
  - DMG file
  - SHA256 checksum
  - Release notes from CHANGELOG

## Automated Build Script

Save this as `build.sh`:

```bash
#!/bin/bash
set -e

echo "🔨 Building OTP Extractor..."

# Clean
xcodebuild clean -project OTPExtractor.xcodeproj -scheme OTPExtractor

# Build
xcodebuild -project OTPExtractor.xcodeproj \
           -scheme OTPExtractor \
           -configuration Release \
           -derivedDataPath build \
           build

# Sign (optional - replace with your identity)
# codesign --force --deep --sign "Developer ID Application: Your Name" \
#          build/Build/Products/Release/OTPExtractor.app

echo "✅ Build complete!"
echo "📦 App location: build/Build/Products/Release/OTPExtractor.app"

# Optional: Open in Finder
open build/Build/Products/Release/
```

Make executable: `chmod +x build.sh`

## Quick Reference

| Command | Description |
|---------|-------------|
| `⌘B` | Build |
| `⌘R` | Run |
| `⌘.` | Stop |
| `⌘K` | Clean build folder |
| `⌘U` | Run tests |

---

For questions or issues, see the main README.md or open an issue on GitHub.
