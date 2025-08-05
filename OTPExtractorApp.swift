//
//  Created by Error
//
import SwiftUI
import AppKit
import SQLite
import AVFoundation

// A struct to hold detailed information about each OTP.
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
            EmptyView()
        }
    }
}

// MARK: - AppDelegate
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var otpManager: OTPManager?
    private var hasPermission: Bool = false

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "key.viewfinder", accessibilityDescription: "OTP Extractor")
        }

        otpManager = OTPManager(statusItem: statusItem)
        
        checkPermissionsAndSetup()
    }
    
    @objc func checkPermissionsAndSetup() {
        self.hasPermission = otpManager?.hasFullDiskAccess() ?? false
        
        if hasPermission {
            otpManager?.startMonitoring { [weak self] in
                DispatchQueue.main.async {
                    self?.setupMenu()
                }
            }
            otpManager?.fetchLastOTP()
        } else {
            showPermissionsAlert()
        }
        
        setupMenu()
    }
    
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
        
        let quitMenuItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitMenuItem.target = self
        menu.addItem(quitMenuItem)

        statusItem?.menu = menu
    }

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

    @objc func copyHistoryItem(_ sender: NSMenuItem) {
        if let code = sender.representedObject as? String {
            copyToClipboard(text: code)
            NSSound(named: "Submarine")?.play()
            print("Copied \(code) from history.")
        }
    }
    
    @objc func clearHistory() {
        otpManager?.clearHistory()
        setupMenu()
    }

    @objc func fetchLastOTPManual() {
        print("Manual fetch triggered.")
        otpManager?.fetchLastOTP()
    }
    
    private func copyToClipboard(text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(self)
    }
}

// MARK: - OTP Manager
class OTPManager {
    private var dbPath: String
    private var lastCheckedMessageID: Int = 0
    private var timer: Timer?
    private weak var statusItem: NSStatusItem?
    
    private(set) var otpHistory: [OTPInfo] = []
    
    private var onUpdate: (() -> Void)?

    init(statusItem: NSStatusItem?) {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        self.dbPath = homeDir.appendingPathComponent("Library/Messages/chat.db").path
        self.statusItem = statusItem
    }
    
    func hasFullDiskAccess() -> Bool {
        return FileManager.default.isReadableFile(atPath: dbPath)
    }

    func startMonitoring(onUpdate: @escaping () -> Void) {
        guard timer == nil else { return }
        
        self.onUpdate = onUpdate
        self.lastCheckedMessageID = fetchLastMessageID()
        print("Monitoring started. Last message ID: \(self.lastCheckedMessageID)")
        
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.fetchLastOTP()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    func clearHistory() {
        self.otpHistory = []
        print("OTP history cleared.")
    }

    private func fetchLastMessageID() -> Int {
        guard hasFullDiskAccess() else { return 0 }
        do {
            let db = try Connection(dbPath, readonly: true)
            let messageTable = Table("message")
            let rowid = Expression<Int>("ROWID")
            
            if let lastMessage = try db.prepare(messageTable.order(rowid.desc).limit(1)).first(where: { _ in true }) {
                return lastMessage[rowid]
            }
        } catch {
            print("Failed to get last message ID: \(error.localizedDescription)")
        }
        return 0
    }
    
    func fetchLastOTP() {
        guard hasFullDiskAccess() else {
            print("Permission denied. Skipping fetch.")
            return
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
                    if let code = self.extractOTP(from: text) {
                        let sender = message[handleTable[handleIdStringCol]]
                        let appleEpoch = message[messageTable[dateCol]]
                        let unixEpoch = Double(appleEpoch) / 1_000_000_000 + 978307200
                        let date = Date(timeIntervalSince1970: unixEpoch)
                        
                        otpInfoFound = OTPInfo(code: code, sender: sender, date: date)
                        break
                    }
                }
            }
            
            if newestIdInDb > self.lastCheckedMessageID {
                self.lastCheckedMessageID = newestIdInDb
            }

            if let info = otpInfoFound {
                print("OTP Found: \(info.code) from \(info.sender)")
                
                if !otpHistory.contains(where: { $0.code == info.code && $0.date == info.date }) {
                    otpHistory.insert(info, at: 0)
                    if otpHistory.count > 3 {
                        otpHistory.removeLast()
                    }
                }
                
                copyToClipboard(text: info.code)
                animateStatusItemSuccess()
                playSound()
                
                onUpdate?()
            }
        } catch {
            print("Database query failed: \(error.localizedDescription)")
            animateStatusItemFailure()
        }
    }

    private func extractOTP(from text: String) -> String? {
        // IMPROVED LOGIC: A more robust two-step process.
        
        // Step 1: Check if the message contains any OTP-related keywords. This is a fast way
        // to discard irrelevant messages without performing complex regex on them.
        let keywords = ["code", "password", "OTP", "verification", "2FA", "token", "PIN", "קוד", "סיסמה", "אימות", "G-"]
        let keywordPattern = "(?i)(" + keywords.joined(separator: "|") + ")"
        
        guard text.range(of: keywordPattern, options: .regularExpression) != nil else {
            // No keywords found, so it's not an OTP message.
            return nil
        }
        
        // Step 2: If a keyword was found, now search for a standalone 5-8 digit number.
        // `\b` is a "word boundary," which ensures we match whole numbers and not digits
        // that are part of a longer string (like a phone number or order ID).
        let numberPattern = #"\b(\d{5,8})\b"#
        
        do {
            let regex = try NSRegularExpression(pattern: numberPattern, options: [])
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            
            // Find the first standalone number in the message.
            if let match = regex.firstMatch(in: text, options: [], range: range) {
                // The range at index 0 is the full match for this simple pattern.
                if let swiftRange = Range(match.range(at: 0), in: text) {
                    let code = String(text[swiftRange])
                    return code
                }
            }
        } catch {
            print("Regex error: \(error.localizedDescription)")
        }
        
        return nil
    }

    private func copyToClipboard(text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        print("\(text) copied to clipboard.")
    }
    
    private func playSound() {
        NSSound(named: "Submarine")?.play()
    }
    
    // MARK: - UI Feedback Animations
    private func animateStatusItemSuccess() {
        DispatchQueue.main.async {
            self.statusItem?.button?.image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "OTP Copied")
            self.statusItem?.button?.contentTintColor = .systemGreen
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.statusItem?.button?.image = NSImage(systemSymbolName: "key.viewfinder", accessibilityDescription: "OTP Extractor")
                self.statusItem?.button?.contentTintColor = nil
            }
        }
    }

    private func animateStatusItemFailure() {
        DispatchQueue.main.async {
            self.statusItem?.button?.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: "Error")
            self.statusItem?.button?.contentTintColor = .systemRed

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.statusItem?.button?.image = NSImage(systemSymbolName: "key.viewfinder", accessibilityDescription: "OTP Extractor")
                self.statusItem?.button?.contentTintColor = nil
            }
        }
    }
}
