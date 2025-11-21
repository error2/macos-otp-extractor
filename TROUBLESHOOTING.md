# Troubleshooting Guide for OTP Extractor

## Common Issues When Running from Xcode

### Issue 1: "Full Disk Access denied" (Even Though It's Enabled)

**Cause:** When you run the app from Xcode, it executes from a temporary DerivedData folder, not from `/Applications`. Full Disk Access permissions are tied to the **specific binary path**.

**Solution:**

#### Option A: Add the Xcode Build to Full Disk Access (For Testing)

1. **Run the app from Xcode** (⌘R)
2. **Check the Console logs** - Look for the line:
   ```
   App running from: /Users/YOUR_USERNAME/Library/Developer/Xcode/DerivedData/OTPExtractor-XXXXXX/Build/Products/Debug/OTPExtractor.app
   ```
3. **Copy that exact path**
4. **Open System Settings** > Privacy & Security > Full Disk Access
5. Click the **lock icon** to unlock (may need admin password)
6. Click the **`+` button**
7. Press **⌘⇧G** (Go to Folder) and paste the path
8. Navigate to and select `OTPExtractor.app`
9. **Enable the toggle** next to the app
10. **Stop and restart** the app in Xcode (⌘. then ⌘R)

**⚠️ Important:** The DerivedData path changes with each clean build! If you clean your project, you'll need to re-add the new path.

#### Option B: Build and Run from /Applications (Recommended)

1. **Build in Xcode** (⌘B)
2. **Product** > Show Build Folder in Finder
3. **Copy** `OTPExtractor.app` to `/Applications/`
4. **Open System Settings** > Privacy & Security > Full Disk Access
5. Click **`+`** and add `/Applications/OTPExtractor.app`
6. **Enable the toggle**
7. **Launch the app** from `/Applications/` (not from Xcode)
8. **Restart the app** if needed

This method is more stable because the path doesn't change.

---

### Issue 2: "Notifications are not allowed for this application"

**Cause:** Notification permissions require:
- Proper app signing
- The app to be registered with the system (notarized or from a known location)

**Solutions:**

#### Quick Fix: Reset Notification Permissions

1. **Quit the app completely**
2. Run this command in Terminal:
   ```bash
   tccutil reset Notifications com.error.OTPExtractor
   ```
   (Replace `com.error.OTPExtractor` with your actual bundle identifier)
3. **Restart the app** - it will prompt for notification permission again

#### Alternative: Check System Settings

1. **System Settings** > Notifications
2. Scroll down and find **OTPExtractor**
3. If it's not there, the app isn't properly registered
4. **Enable "Allow Notifications"** if present
5. Select notification style: **Banners** (recommended)
6. **Restart the app**

#### For Development Builds:

Running unsigned apps from Xcode may cause notification issues. Try:

1. **Enable code signing** in Xcode:
   - Select project in navigator
   - Go to **Signing & Capabilities**
   - Select your **Team**
   - Enable **"Automatically manage signing"**

2. **Or disable notifications during development:**
   - Set `notificationsEnabled` to `false` in preferences
   - This won't affect the core OTP extraction functionality

---

### Issue 3: App Crashes or Doesn't Appear in Menu Bar

**Check Console for Errors:**

1. Open **Console.app** (in `/Applications/Utilities/`)
2. Filter by: `process:OTPExtractor`
3. Look for crash reports or error messages
4. Common issues:
   - Missing SQLite.swift package
   - Code signing issues
   - Entitlements misconfigured

**Verify SQLite.swift is Added:**

1. In Xcode, select the project
2. Select the **OTPExtractor target**
3. Go to **General** > Frameworks, Libraries, and Embedded Content
4. Verify **SQLite** is listed
5. If not, go to **File** > Add Package Dependencies
6. Add: `https://github.com/stephencelis/SQLite.swift.git`

---

### Issue 4: App Asks for Permission Every Launch

**Cause:** The app path keeps changing (common with Xcode DerivedData)

**Solution:** Use Option B from Issue 1 - run from `/Applications/` instead of Xcode.

---

### Issue 5: No OTPs Detected Even with Permissions

**Debugging Steps:**

1. **Check Console logs** for:
   ```
   Checking Full Disk Access for: /Users/YOUR_USERNAME/Library/Messages/chat.db
   Can read Messages database: true
   ```

2. **Send yourself a test OTP:**
   - Use a service that sends verification codes
   - Watch the Console for "OTP Found" messages

3. **Try manual fetch:**
   - Click menu bar icon
   - Select "Fetch Last OTP Manually"
   - Check if alert shows "No OTP Found" or if code is copied

4. **Verify Message Format:**
   - The app looks for keywords like: code, verification, OTP, 2FA, etc.
   - The OTP must be 4-9 digits or 6-8 alphanumeric characters
   - Test with a message like: "Your verification code is 123456"

---

## Quick Diagnostic Checklist

Run through this checklist when troubleshooting:

- [ ] **Console shows the app path** - Note it down
- [ ] **Full Disk Access granted** for the **exact app path**
- [ ] **App restarted** after granting permissions
- [ ] **Messages database path** is correct (check Console)
- [ ] **Can read database** = `true` in Console logs
- [ ] **Notification permissions** granted (or disabled in preferences)
- [ ] **SQLite package** is added and linked
- [ ] **Test message sent** with clear OTP format

---

## Getting Detailed Logs

To see all debug information:

1. **Open Console.app**
2. Click **Action** > Include Info Messages
3. Click **Action** > Include Debug Messages
4. Filter by: `subsystem:com.error.OTPExtractor`
5. **Run the app** and watch for detailed logs

Key log messages to look for:
```
✅ App running from: [path]
✅ OTP regex patterns compiled successfully
✅ Checking Full Disk Access for: [database path]
✅ Can read Messages database: true
✅ Monitoring started. Last message ID: [number]
✅ File system monitoring setup successfully
✅ OTP Found: [code] from [sender]
```

---

## Still Having Issues?

1. **Clean build folder**: ⌘K in Xcode, then rebuild
2. **Reset all permissions**:
   ```bash
   tccutil reset All com.error.OTPExtractor
   ```
3. **Check macOS version**: Requires macOS 13.0+ (Ventura or later)
4. **Verify Messages app works**: Make sure iMessage/SMS is receiving messages
5. **Check bundle identifier**: Must match in Xcode and System Settings

---

## Testing Without Messages Database

To verify the app is working without needing Full Disk Access, you can temporarily comment out the permission check for testing:

**DO NOT SHIP WITH THIS CHANGE - FOR TESTING ONLY**

This is just to verify the app launches and UI works correctly.

---

## Production Checklist

Before distributing your app:

- [ ] Code signed with Developer ID
- [ ] Notarized by Apple
- [ ] Hardened runtime enabled
- [ ] Entitlements properly configured
- [ ] Tested on clean macOS install
- [ ] Full Disk Access instructions in README
- [ ] Privacy policy included (if needed)

---

For more help, check the main README.md or open an issue on GitHub.
