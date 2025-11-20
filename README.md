# OTP Extractor for macOS

A lightweight and efficient macOS menu bar utility that automatically reads One-Time Passcodes (OTPs) from the Messages app and copies them to the clipboard.

## Overview

This application lives in your macOS menu bar and silently monitors for new messages that contain verification codes. When a new OTP is detected, it's instantly copied to your clipboard, saving you the time and effort of switching to the Messages app, finding the code, and copying it manually.

## Features

### Core Functionality
* **Automatic OTP Detection:** Uses advanced regex patterns to find and extract 4-9 digit codes and 6-8 character alphanumeric codes from incoming messages
* **Clipboard Integration:** Automatically copies the found OTP to the system clipboard
* **Smart Detection:** Two-step keyword + regex approach minimizes false positives
* **Multi-Language Support:** Detects OTPs in English and Hebrew messages

### Security
* **Auto-Clear Clipboard:** Optionally clears the clipboard after a configurable delay (default: 60 seconds) for enhanced security
* **Read-Only Access:** Uses read-only database access - never modifies your messages
* **Privacy-Focused:** All processing happens locally on your device

### User Experience
* **Rich OTP History:** The menu displays recent codes with sender and time information
* **Configurable History Size:** Keep 1-10 recent codes (default: 3)
* **Visual Feedback:** The menu bar icon provides instant visual feedback with color-coded animations
* **Notifications:** Optional system notifications when OTP codes are detected
* **Auditory Feedback:** Optional system sound confirmation
* **Manual Fetch:** Menu option to manually trigger a check for the last OTP

### Performance
* **File System Events:** Uses FSEvents API for efficient, battery-friendly monitoring
* **Optimized Regex:** Pre-compiled regex patterns for maximum performance
* **Configurable Polling:** Adjust monitoring frequency (1-30 seconds) in preferences

### Customization
* **Preferences Window:** Easy-to-use settings interface (⌘,)
* **Adjustable Polling Interval:** Fine-tune monitoring frequency
* **Notification Controls:** Toggle notifications and sounds independently
* **History Management:** Configurable history size with clear confirmation

## What's New in v1.3.0

### Major Improvements
- ✅ **Alphanumeric OTP Support** - Now detects codes like "ABC123" and "G-123456"
- ✅ **FSEvents Monitoring** - 50-70% reduction in CPU usage with file system event monitoring
- ✅ **Auto-Clear Clipboard** - Enhanced security with configurable auto-clear (10-300 seconds)
- ✅ **Preferences Window** - Full settings UI accessible via ⌘, or menu
- ✅ **User Notifications** - Optional system notifications for OTP detection
- ✅ **Expanded Hebrew Support** - Added "סיסמתך" and improved Hebrew keyword detection
- ✅ **Confirmation Dialogs** - Prevent accidental history clearing
- ✅ **Manual Fetch Feedback** - Shows alert when no OTP is found
- ✅ **Version Display** - See current version in menu bar

### Code Quality Improvements
- ✅ **Performance** - Pre-compiled regex patterns (no runtime compilation overhead)
- ✅ **Memory Management** - Proper weak references prevent retain cycles
- ✅ **Error Handling** - Comprehensive error handling with os.log integration
- ✅ **Code Organization** - Modular architecture with separate manager classes
- ✅ **Documentation** - Inline documentation for all major methods
- ✅ **Constants Management** - All magic numbers extracted to Constants.swift
- ✅ **No Code Duplication** - Centralized ClipboardManager

### Bug Fixes
- Fixed inefficient `.first(where: { _ in true })` usage
- Removed unused AVFoundation import
- Fixed OTP pattern to support 4-digit PINs and 9-digit codes
- Better date conversion using proper constants

## Download

For users who don't want to build from source, you can download the pre-compiled application here.

* [**Download OTP Extractor v1.3**](https://github.com/error2/macos-otp-extractor/releases/download/v1.3/OTPExtractor.app.zip) *(Coming Soon)*
* [**Download OTP Extractor v1.2**](https://github.com/error2/macos-otp-extractor/releases/download/v1.2/OTPExtractor.app.zip) *(Current Stable)*

You can also visit the [Releases page](https://github.com/error2/macos-otp-extractor/releases) for all available versions.

## How It Works

The app works by directly and securely reading the local `chat.db` SQLite database where the macOS Messages app stores all message history. It uses two complementary methods:

1. **FSEvents Monitoring** - Watches the database file for changes and triggers immediate checks
2. **Timer-Based Polling** - Fallback polling at configurable intervals (default: 5 seconds)

When a message arrives, the app:
1. Checks for OTP-related keywords (fast filtering)
2. Applies regex patterns to extract numeric or alphanumeric codes
3. Copies the code to clipboard with optional auto-clear
4. Updates the history and provides visual/audio/notification feedback

This method is read-only and does not modify any of your messages or data.

## Setup & Installation (from Source)

If you prefer to build the app yourself, follow these instructions.

### Prerequisites

* A Mac running macOS 13.0 (Ventura) or later
* Xcode 14.0 or later

### Build Instructions

1.  **Clone the Repository:**
    ```bash
    git clone https://github.com/error2/macos-otp-extractor.git
    cd macos-otp-extractor
    ```

2.  **Open in Xcode:**
    Open the `.xcodeproj` file in Xcode.

3.  **Add Dependencies:**
    In Xcode, go to **File > Add Package Dependencies...** and add the `SQLite.swift` package:
    ```
    https://github.com/stephencelis/SQLite.swift.git
    ```

4.  **Build the App:**
    From the menu bar, select **Product > Build** (or press **⌘B**).

### Permissions (Crucial Step)

For the app to read your messages, you must grant it **Full Disk Access**.

1.  After building the app, find `OTPExtractor.app` in the **Products** folder in Xcode's Project Navigator. Right-click and select **"Show in Finder"**.
2.  Open **System Settings > Privacy & Security > Full Disk Access**.
3.  Click the `+` button and add the `OTPExtractor.app` file.
4.  Ensure the toggle next to the app is enabled.
5.  **Restart the app** after granting permissions.

### Notification Permissions

On first launch, the app will request permission to send notifications. This is optional but recommended for the best experience.

### Final Installation

1.  Drag the `OTPExtractor.app` file from the build folder into your main `/Applications` folder.
2.  (Recommended) To have the app launch on startup, go to **System Settings > General > Login Items** and add `OTPExtractor` to the list of apps to open at login.

## Usage

### Basic Usage
- Launch the app - it appears in your menu bar with a key icon
- Grant Full Disk Access when prompted
- The app will automatically detect and copy OTP codes from new messages

### Accessing Preferences
- Click the menu bar icon and select "Preferences..." (or press ⌘,)
- Customize polling interval, history size, clipboard auto-clear, and notifications

### Manual OTP Fetch
- Click the menu bar icon and select "Fetch Last OTP Manually" (or press ⌘F)
- Useful if you missed an OTP or want to re-copy it

### Viewing History
- Click the menu bar icon to see recent OTP codes
- Click any history item to copy it again
- Use "Clear History" to remove all saved codes (with confirmation)

## Preferences Explained

### Monitoring
- **Polling Interval** (1-30s): How often to check for new messages. Lower = more responsive but uses more CPU. Default: 5s.

### History
- **Keep last N codes** (1-10): Number of recent codes to display. Default: 3.

### Security
- **Auto-clear clipboard**: Automatically clear clipboard after specified time
- **Clear after** (10-300s): Delay before clearing. Default: 60s.

### Notifications
- **Show notifications**: Display system notification when OTP detected
- **Play sound**: Play system sound on detection

## Supported OTP Formats

### Numeric Codes
- 4-9 digits (e.g., 1234, 123456, 123456789)
- Must be standalone numbers (word boundaries)

### Alphanumeric Codes
- 6-8 characters, uppercase letters and numbers (e.g., ABC123, G-123456)
- Must contain at least one digit

### Keyword Triggers (English)
code, verification, OTP, 2FA, token, PIN, verify, authentication, confirm, G-

### Keyword Triggers (Hebrew)
קוד, סיסמה, סיסמתך, אימות

## Technology Stack

* **Language:** Swift
* **UI Framework:** SwiftUI (preferences) and AppKit (menu bar)
* **Database:** [SQLite.swift](https://github.com/stephencelis/SQLite.swift) for Messages database interaction
* **Logging:** Unified Logging System (os.log) for performance and debugging
* **File Monitoring:** DispatchSource with FSEvents for efficient file watching

## Project Structure

```
OTPExtractor/
├── OTPExtractorApp.swift       # Main app, AppDelegate, OTPManager
├── Constants.swift             # App-wide constants and configuration
├── ClipboardManager.swift      # Clipboard operations with auto-clear
├── PreferencesManager.swift    # UserDefaults wrapper
├── PreferencesWindow.swift     # SwiftUI preferences interface
├── OTPExtractor.entitlements   # App entitlements
└── Assets.xcassets/            # App icons and assets
```

## Troubleshooting

### App doesn't detect OTPs
1. Ensure Full Disk Access is granted in System Settings
2. Restart the app after granting permissions
3. Check that Messages.app is storing messages locally
4. Try manual fetch to verify functionality

### Clipboard auto-clear not working
1. Check that auto-clear is enabled in Preferences
2. Verify the delay is set correctly
3. Ensure you haven't copied other content (auto-clear only clears if clipboard unchanged)

### High CPU usage
1. Increase polling interval in Preferences (e.g., 10-30 seconds)
2. FSEvents monitoring should keep CPU usage low automatically

### Notifications not showing
1. Check notification permissions in System Settings > Notifications > OTP Extractor
2. Enable "Show notifications" in app Preferences

## Privacy & Security

- All processing happens **locally** on your device
- The app has **read-only** access to the Messages database
- No data is sent to external servers
- No analytics or tracking
- Clipboard auto-clear enhances security for sensitive codes
- Open source - audit the code yourself!

## Known Limitations

- Requires Full Disk Access to read Messages database
- Only works with Messages.app (iMessage/SMS)
- May occasionally detect non-OTP numbers if they match the pattern
- Alphanumeric detection limited to 6-8 character codes

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development Guidelines
- Follow Swift API Design Guidelines
- Add inline documentation for complex logic
- Test on multiple macOS versions
- Maintain existing code style

## Future Enhancements

- [ ] Machine learning for better OTP detection accuracy
- [ ] Support for third-party messaging apps
- [ ] Keychain integration for secure history storage
- [ ] Auto-update mechanism
- [ ] Dark mode icon variants
- [ ] Accessibility improvements
- [ ] Localization for more languages

## License

This project is provided as-is for personal and educational use.

## Credits

Created by Error
Built with ❤️ for the macOS community

---

**⚠️ Disclaimer:** This application accesses your Messages database for legitimate OTP extraction purposes. Please ensure you trust any software that requests Full Disk Access. Always download from official sources or build from source yourself.

*This project was created for personal use and demonstrates interaction with system files on macOS.*
