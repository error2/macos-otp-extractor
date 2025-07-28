# OTP Extractor for macOS

A lightweight and efficient macOS menu bar utility that automatically reads One-Time Passcodes (OTPs) from the Messages app and copies them to the clipboard.

*(Note: The menu now includes a rich history of recent codes.)*

## Overview

This application lives in your macOS menu bar and silently monitors for new messages that contain verification codes. When a new OTP is detected, it's instantly copied to your clipboard, saving you the time and effort of switching to the Messages app, finding the code, and copying it manually.

## Features

* **Automatic OTP Detection:** Uses regular expressions to find and extract 5-8 digit codes from incoming messages.
* **Clipboard Integration:** Automatically copies the found OTP to the system clipboard.
* **Rich OTP History:** The menu displays the last 3 codes that were captured, including the sender and the time the message was received. You can click any item in the history to copy it again.
* **Visual Feedback:** The menu bar icon provides instant visual feedback (e.g., a green checkmark) when a code is successfully copied.
* **Auditory Feedback:** Plays a subtle system sound to confirm an OTP has been copied.
* **Efficient:** Uses a timer to check for new messages periodically without consuming significant system resources.
* **Manual Fetch:** Includes a menu option to manually trigger a check for the last OTP.

## Download

For users who don't want to build from source, you can download the pre-compiled application here.

* [**Download OTP Extractor v1.1**](https://github.com/error2/macos-otp-extractor/releases/download/v1.1/OTPExtractor.app.zip)

You can also visit the [Releases page](https://github.com/error2/macos-otp-extractor/releases) for all available versions.

## How It Works

The app works by directly and securely reading the local `chat.db` SQLite database where the macOS Messages app stores all message history. It periodically checks for new entries, parses their content for a valid OTP, and if found, copies it to the clipboard and updates the history.

This method is read-only and does not modify any of your messages or data.

## Setup & Installation (from Source)

If you prefer to build the app yourself, follow these instructions.

### Prerequisites

* A Mac running macOS.
* Xcode installed.

### Build Instructions

1.  **Clone the Repository:**
    ```bash
    git clone [https://github.com/error2/macos-otp-extractor.git](https://github.com/error2/macos-otp-extractor.git)
    cd macos-otp-extractor
    ```
2.  **Open in Xcode:** Open the `.xcodeproj` file.
3.  **Add Dependencies:** In Xcode, go to **File > Add Package Dependencies...** and add the `SQLite.swift` package: `https://github.com/stephencelis/SQLite.swift.git`.
4.  **Build the App:** From the menu bar, select **Product > Build** (or press **Cmd + B**).

### Permissions (Crucial Step)

For the app to read your messages, you must grant it **Full Disk Access**.

1.  After building the app, find `OTPExtractor.app` in the **Products** folder in Xcode's Project Navigator. Right-click and select **"Show in Finder"**.
2.  Open **System Settings > Privacy & Security > Full Disk Access**.
3.  Click the `+` button and add the `OTPExtractor.app` file.
4.  Ensure the toggle next to the app is enabled.

### Final Installation

1.  Drag the `OTPExtractor.app` file from the build folder into your main `/Applications` folder.
2.  (Recommended) To have the app launch on startup, go to **System Settings > General > Login Items** and add `OTPExtractor` to the list of apps to open at login.

## Technology Stack

* **Language:** Swift
* **UI Framework:** SwiftUI (for the app structure) and AppKit (for the menu bar item)
* **Database:** [SQLite.swift](https://github.com/stephencelis/SQLite.swift) for interacting with the Messages database.

---

*This project was created for personal use and demonstrates interaction with system files on macOS.*
