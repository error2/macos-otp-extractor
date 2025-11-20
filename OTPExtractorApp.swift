//
//  OTPExtractorApp.swift
//  OTPExtractor
//
//  Created by Error
//

import SwiftUI
import AppKit
import SQLite
import UserNotifications
import os.log

// MARK: - OTP Information Model

/// A struct to hold detailed information about each OTP.
struct OTPInfo: Hashable {
    let code: String
    let sender: String
    let date: Date
}

// MARK: - Main Application

@main
struct OTPExtractorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            PreferencesView()
        }
    }
}

// MARK: - AppDelegate

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    var statusItem: NSStatusItem?
    var otpManager: OTPManager?
    private var hasPermission: Bool = false
    private var preferencesWindow: NSWindow?
    private let logger = Logger(subsystem: "com.error.OTPExtractor", category: "AppDelegate")

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Setup notification center
        UNUserNotificationCenter.current().delegate = self
        requestNotificationPermission()

        // Setup status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "key.viewfinder", accessibilityDescription: "OTP Extractor")
        }

        otpManager = OTPManager(statusItem: statusItem)

        // Listen for preferences changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(preferencesChanged),
            name: Notification.Name("PreferencesChanged"),
            object: nil
        )

        checkPermissionsAndSetup()
    }

    // MARK: - Notification Permissions

    private func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                self.logger.error("Notification permission error: \(error.localizedDescription)")
            } else {
                self.logger.info("Notification permission granted: \(granted)")
            }
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    // MARK: - Permissions Check

    @objc func checkPermissionsAndSetup() {
        hasPermission = otpManager?.hasFullDiskAccess() ?? false

        if hasPermission {
            logger.info("Full Disk Access granted")
            otpManager?.startMonitoring { [weak self] in
                DispatchQueue.main.async {
                    self?.setupMenu()
                }
            }
            otpManager?.fetchLastOTP()
        } else {
            logger.warning("Full Disk Access denied")
            showPermissionsAlert()
        }

        setupMenu()
    }

    @objc func preferencesChanged() {
        logger.info("Preferences changed, reloading...")
        otpManager?.reloadPreferences()
        setupMenu()
    }

    // MARK: - Menu Setup

    @objc func setupMenu() {
        let menu = NSMenu()

        if hasPermission {
            // --- Full Menu (Permission Granted) ---
            if let history = otpManager?.otpHistory, !history.isEmpty {
                let historyTitle = NSMenuItem(title: "Recent Codes", action: nil, keyEquivalent: "")
                historyTitle.isEnabled = false
                menu.addItem(historyTitle)

                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "h:mm a"

                for info in history {
                    let formattedTime = timeFormatter.string(from: info.date)
                    let title = "\(info.code) from \(info.sender) (\(formattedTime))"
                    let historyItem = NSMenuItem(title: title, action: #selector(copyHistoryItem(_:)), keyEquivalent: "")
                    historyItem.representedObject = info.code
                    historyItem.target = self
                    menu.addItem(historyItem)
                }
                menu.addItem(NSMenuItem.separator())

                let clearHistoryItem = NSMenuItem(title: "Clear History", action: #selector(clearHistory), keyEquivalent: "")
                clearHistoryItem.target = self
                menu.addItem(clearHistoryItem)

                menu.addItem(NSMenuItem.separator())
            }

            let fetchMenuItem = NSMenuItem(title: "Fetch Last OTP Manually", action: #selector(fetchLastOTPManual), keyEquivalent: "F")
            fetchMenuItem.target = self
            menu.addItem(fetchMenuItem)
        } else {
            // --- Limited Menu (Permission Denied) ---
            let permissionTitle = NSMenuItem(title: "Permission Required", action: nil, keyEquivalent: "")
            permissionTitle.isEnabled = false
            menu.addItem(permissionTitle)

            let checkAgainItem = NSMenuItem(title: "Check Permissions Again", action: #selector(checkPermissionsAndSetup), keyEquivalent: "")
            checkAgainItem.target = self
            menu.addItem(checkAgainItem)
        }

        menu.addItem(NSMenuItem.separator())

        // Preferences menu item
        let preferencesItem = NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ",")
        preferencesItem.target = self
        menu.addItem(preferencesItem)

        menu.addItem(NSMenuItem.separator())

        // Version display
        let versionItem = NSMenuItem(title: "Version \(Constants.appVersion)", action: nil, keyEquivalent: "")
        versionItem.isEnabled = false
        menu.addItem(versionItem)

        menu.addItem(NSMenuItem.separator())

        let quitMenuItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitMenuItem.target = self
        menu.addItem(quitMenuItem)

        statusItem?.menu = menu
    }

    // MARK: - Alert Dialogs

    /// Shows alert when Full Disk Access permission is required
    func showPermissionsAlert() {
        let alert = NSAlert()
        alert.messageText = "Full Disk Access Required"
        alert.informativeText = "OTP Extractor needs Full Disk Access to read codes from the Messages app. Please grant permission in System Settings."
        alert.alertStyle = .warning

        let openButton = alert.addButton(withTitle: "Open Settings")
        openButton.target = self
        openButton.action = #selector(openPrivacySettings)

        alert.addButton(withTitle: "OK")

        alert.runModal()
    }

    @objc func openPrivacySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Menu Actions

    @objc func copyHistoryItem(_ sender: NSMenuItem) {
        if let code = sender.representedObject as? String {
            ClipboardManager.shared.copy(text: code, autoClear: PreferencesManager.shared.autoClipboardClear)
            if PreferencesManager.shared.soundEnabled {
                NSSound(named: "Submarine")?.play()
            }
            logger.info("Copied code from history: \(code, privacy: .private)")
        }
    }

    @objc func clearHistory() {
        // Show confirmation dialog
        let alert = NSAlert()
        alert.messageText = "Clear History?"
        alert.informativeText = "This will remove all saved OTP codes from the menu. This action cannot be undone."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Clear")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            otpManager?.clearHistory()
            setupMenu()
            logger.info("History cleared by user")
        }
    }

    @objc func fetchLastOTPManual() {
        logger.info("Manual fetch triggered")
        let foundOTP = otpManager?.fetchLastOTP() ?? false

        if !foundOTP {
            // Show feedback when no OTP is found
            let alert = NSAlert()
            alert.messageText = "No OTP Found"
            alert.informativeText = "No recent OTP code was detected in your messages."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    @objc func openPreferences() {
        // Check if preferences window already exists
        if let window = preferencesWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            return
        }

        // Create new preferences window
        let contentView = PreferencesView()
        let hostingController = NSHostingController(rootView: contentView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "Preferences"
        window.styleMask = [.titled, .closable]
        window.center()
        window.setFrameAutosaveName("PreferencesWindow")

        preferencesWindow = window
        window.makeKeyAndOrderFront(nil)

        logger.info("Preferences window opened")
    }

    @objc func quitApp() {
        logger.info("Application quit by user")
        NSApplication.shared.terminate(self)
    }
}

// MARK: - OTP Manager

class OTPManager {
    private var dbPath: String
    private var lastCheckedMessageID: Int = 0
    private var timer: Timer?
    private var fileMonitor: DispatchSourceFileSystemObject?
    private weak var statusItem: NSStatusItem?
    private let logger = Logger(subsystem: "com.error.OTPExtractor", category: "OTPManager")

    private(set) var otpHistory: [OTPInfo] = []

    private var onUpdate: (() -> Void)?

    // Pre-compiled regex patterns for performance
    private let digitOTPRegex: NSRegularExpression
    private let alphanumericOTPRegex: NSRegularExpression

    init(statusItem: NSStatusItem?) {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        self.dbPath = homeDir.appendingPathComponent(Constants.messagesDBPath).path
        self.statusItem = statusItem

        // Compile regex patterns once during initialization
        do {
            // Pattern for 4-9 digit OTP codes
            let digitPattern = #"\b(\d{4,9})\b"#
            digitOTPRegex = try NSRegularExpression(pattern: digitPattern, options: [])

            // Pattern for alphanumeric codes (6-8 characters, mix of letters and numbers)
            let alphanumericPattern = #"\b([A-Z0-9]{6,8})\b"#
            alphanumericOTPRegex = try NSRegularExpression(pattern: alphanumericPattern, options: [])

            logger.info("OTP regex patterns compiled successfully")
        } catch {
            // This should never happen with hardcoded patterns, but handle it anyway
            fatalError("Failed to compile OTP regex patterns: \(error.localizedDescription)")
        }
    }

    // MARK: - Permission Check

    /// Checks if the app has Full Disk Access to read the Messages database
    /// - Returns: `true` if the database is readable, `false` otherwise
    func hasFullDiskAccess() -> Bool {
        return FileManager.default.isReadableFile(atPath: dbPath)
    }

    // MARK: - Monitoring

    /// Starts monitoring for new OTP messages using FSEvents for efficiency
    /// - Parameter onUpdate: Callback to execute when the UI should be updated
    func startMonitoring(onUpdate: @escaping () -> Void) {
        guard timer == nil else { return }

        self.onUpdate = onUpdate
        self.lastCheckedMessageID = fetchLastMessageID()
        logger.info("Monitoring started. Last message ID: \(self.lastCheckedMessageID)")

        // Setup file system monitoring using FSEvents
        setupFileMonitoring()

        // Fallback timer-based polling
        let interval = PreferencesManager.shared.pollingInterval
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.fetchLastOTP()
        }

        logger.info("Timer polling started with interval: \(interval)s")
    }

    /// Sets up FSEvents-based file monitoring for the Messages database
    private func setupFileMonitoring() {
        guard hasFullDiskAccess() else {
            logger.warning("Cannot setup file monitoring without Full Disk Access")
            return
        }

        let fileDescriptor = open(dbPath, O_EVTONLY)
        guard fileDescriptor >= 0 else {
            logger.error("Failed to open database for monitoring")
            return
        }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .extend],
            queue: DispatchQueue.global(qos: .background)
        )

        source.setEventHandler { [weak self] in
            self?.logger.debug("Database file changed, checking for new OTPs")
            self?.fetchLastOTP()
        }

        source.setCancelHandler {
            close(fileDescriptor)
        }

        source.resume()
        fileMonitor = source

        logger.info("File system monitoring setup successfully")
    }

    /// Stops all monitoring activities
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        fileMonitor?.cancel()
        fileMonitor = nil
        logger.info("Monitoring stopped")
    }

    /// Reloads preferences and restarts monitoring if needed
    func reloadPreferences() {
        let wasMonitoring = timer != nil
        stopMonitoring()

        if wasMonitoring, let callback = onUpdate {
            startMonitoring(onUpdate: callback)
        }

        // Trim history if max size changed
        let maxSize = PreferencesManager.shared.maxHistorySize
        if otpHistory.count > maxSize {
            otpHistory = Array(otpHistory.prefix(maxSize))
        }

        logger.info("Preferences reloaded")
    }

    /// Clears the OTP history
    func clearHistory() {
        otpHistory.removeAll()
        logger.info("OTP history cleared")
    }

    // MARK: - Database Operations

    /// Fetches the most recent message ID from the database
    /// - Returns: The ROWID of the most recent message, or 0 if unavailable
    private func fetchLastMessageID() -> Int {
        guard hasFullDiskAccess() else { return 0 }

        do {
            let db = try Connection(dbPath, readonly: true)
            let messageTable = Table("message")
            let rowid = Expression<Int>("ROWID")

            // Fixed: Use makeIterator().next() for SQLite.swift Row sequence
            if let lastMessage = try db.prepare(messageTable.order(rowid.desc).limit(1)).makeIterator().next() {
                return lastMessage[rowid]
            }
        } catch {
            logger.error("Failed to get last message ID: \(error.localizedDescription)")
        }
        return 0
    }

    /// Fetches and processes the last OTP from the Messages database
    /// - Returns: `true` if an OTP was found and processed, `false` otherwise
    @discardableResult
    func fetchLastOTP() -> Bool {
        guard hasFullDiskAccess() else {
            logger.warning("Permission denied. Skipping fetch.")
            return false
        }

        do {
            let db = try Connection(dbPath, readonly: true)

            let messageTable = Table("message")
            let handleTable = Table("handle")

            let textCol = Expression<String?>("text")
            let handleIdCol = Expression<Int>("handle_id")
            let dateCol = Expression<Int>("date")
            let handleIdStringCol = Expression<String>("id")
            let rowid = Expression<Int>("ROWID")

            let query = messageTable
                .join(handleTable, on: messageTable[handleIdCol] == handleTable[rowid])
                .select(messageTable[textCol], handleTable[handleIdStringCol], messageTable[dateCol])
                .filter(messageTable[rowid] > lastCheckedMessageID)
                .order(messageTable[rowid].desc)

            var otpInfoFound: OTPInfo?

            let newestIdInDb = fetchLastMessageID()

            for message in try db.prepare(query) {
                if let text = message[messageTable[textCol]] {
                    if let code = extractOTP(from: text) {
                        let sender = message[handleTable[handleIdStringCol]]
                        let appleEpoch = message[messageTable[dateCol]]

                        // Convert Apple epoch to Unix timestamp
                        let unixEpoch = Double(appleEpoch) / Constants.nanosecondsToSeconds + Constants.appleEpochOffset
                        let date = Date(timeIntervalSince1970: unixEpoch)

                        otpInfoFound = OTPInfo(code: code, sender: sender, date: date)
                        break
                    }
                }
            }

            if newestIdInDb > lastCheckedMessageID {
                lastCheckedMessageID = newestIdInDb
            }

            if let info = otpInfoFound {
                logger.info("OTP Found: \(info.code, privacy: .private) from \(info.sender, privacy: .public)")

                // Add to history if not duplicate
                if !otpHistory.contains(where: { $0.code == info.code && $0.date == info.date }) {
                    otpHistory.insert(info, at: 0)

                    // Trim history to max size
                    let maxSize = PreferencesManager.shared.maxHistorySize
                    if otpHistory.count > maxSize {
                        otpHistory.removeLast()
                    }
                }

                // Copy to clipboard
                ClipboardManager.shared.copy(
                    text: info.code,
                    autoClear: PreferencesManager.shared.autoClipboardClear
                )

                // Visual feedback
                animateStatusItemSuccess()

                // Audio feedback
                if PreferencesManager.shared.soundEnabled {
                    playSound()
                }

                // Send notification
                if PreferencesManager.shared.notificationsEnabled {
                    sendNotification(for: info)
                }

                onUpdate?()
                return true
            }
        } catch {
            logger.error("Database query failed: \(error.localizedDescription)")
            animateStatusItemFailure()
        }

        return false
    }

    // MARK: - OTP Extraction

    /// Extracts OTP code from a message text using a two-step keyword + regex approach
    /// - Parameter text: The message text to analyze
    /// - Returns: The extracted OTP code, or `nil` if no code was found
    private func extractOTP(from text: String) -> String? {
        // Step 1: Check for OTP-related keywords to quickly filter irrelevant messages
        // This includes English, Hebrew, and common OTP patterns
        let keywords = [
            "code", "verification", "OTP", "2FA", "token", "PIN", "verify", "authentication", "confirm",
            "קוד", "סיסמה", "סיסמתך", "אימות", // Hebrew keywords including "your password"
            "G-" // Google verification codes
        ]

        let keywordPattern = "(?i)(" + keywords.joined(separator: "|") + ")"

        guard text.range(of: keywordPattern, options: .regularExpression) != nil else {
            // No keywords found, so it's not an OTP message
            return nil
        }

        // Step 2: Try to find a numeric OTP code (4-9 digits)
        if let code = extractWithRegex(digitOTPRegex, from: text) {
            logger.debug("Found numeric OTP: \(code, privacy: .private)")
            return code
        }

        // Step 3: Try to find an alphanumeric OTP code (6-8 characters)
        if let code = extractWithRegex(alphanumericOTPRegex, from: text) {
            // Additional validation: must contain at least one digit
            if code.contains(where: { $0.isNumber }) {
                logger.debug("Found alphanumeric OTP: \(code, privacy: .private)")
                return code
            }
        }

        return nil
    }

    /// Helper method to extract code using a pre-compiled regex
    /// - Parameters:
    ///   - regex: The compiled NSRegularExpression to use
    ///   - text: The text to search in
    /// - Returns: The first matched code, or `nil` if no match found
    private func extractWithRegex(_ regex: NSRegularExpression, from text: String) -> String? {
        let range = NSRange(text.startIndex..<text.endIndex, in: text)

        if let match = regex.firstMatch(in: text, options: [], range: range) {
            if let swiftRange = Range(match.range(at: 1), in: text) {
                return String(text[swiftRange])
            }
        }

        return nil
    }

    // MARK: - Notifications

    /// Sends a user notification when an OTP is detected
    /// - Parameter info: The OTP information to include in the notification
    private func sendNotification(for info: OTPInfo) {
        let content = UNMutableNotificationContent()
        content.title = "OTP Code Detected"
        content.body = "Code \(info.code) from \(info.sender) copied to clipboard"
        content.sound = PreferencesManager.shared.soundEnabled ? .default : nil

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                self.logger.error("Failed to send notification: \(error.localizedDescription)")
            }
        }
    }

    /// Plays the system sound for OTP detection
    private func playSound() {
        NSSound(named: "Submarine")?.play()
    }

    // MARK: - UI Feedback Animations

    /// Animates the status bar icon to show success (green checkmark)
    private func animateStatusItemSuccess() {
        DispatchQueue.main.async {
            self.statusItem?.button?.image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "OTP Copied")
            self.statusItem?.button?.contentTintColor = .systemGreen

            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.statusIconAnimationDuration) {
                self.statusItem?.button?.image = NSImage(systemSymbolName: "key.viewfinder", accessibilityDescription: "OTP Extractor")
                self.statusItem?.button?.contentTintColor = nil
            }
        }
    }

    /// Animates the status bar icon to show failure (red X)
    private func animateStatusItemFailure() {
        DispatchQueue.main.async {
            self.statusItem?.button?.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: "Error")
            self.statusItem?.button?.contentTintColor = .systemRed

            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.statusIconAnimationDuration) {
                self.statusItem?.button?.image = NSImage(systemSymbolName: "key.viewfinder", accessibilityDescription: "OTP Extractor")
                self.statusItem?.button?.contentTintColor = nil
            }
        }
    }
}
