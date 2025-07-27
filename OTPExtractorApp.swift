//
//  Created by Error
//
import SwiftUI
import AppKit
import SQLite
import AVFoundation

// NEW: A struct to hold detailed information about each OTP.
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

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "key.viewfinder", accessibilityDescription: "OTP Extractor")
        }

        // Initialize the OTP manager
        otpManager = OTPManager(statusItem: statusItem)
        
        // Build the initial menu
        setupMenu()
        
        // Start monitoring for OTPs
        otpManager?.startMonitoring { [weak self] in
            // This completion block is called whenever a new OTP is found.
            // We just need to rebuild the menu to show the new history.
            DispatchQueue.main.async {
                self?.setupMenu()
            }
        }
        
        // Perform an initial check on launch
        otpManager?.fetchLastOTP()
    }
    
    @objc func setupMenu() {
        let menu = NSMenu()

        // --- OTP History Section ---
        if let history = otpManager?.otpHistory, !history.isEmpty {
            let historyTitle = NSMenuItem(title: "Recent Codes", action: nil, keyEquivalent: "")
            historyTitle.isEnabled = false
            menu.addItem(historyTitle)
            
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a" // e.g., "4:45 PM"

            for info in history {
                let formattedTime = timeFormatter.string(from: info.date)
                let title = "\(info.code) from \(info.sender) (\(formattedTime))"
                let historyItem = NSMenuItem(title: title, action: #selector(copyHistoryItem(_:)), keyEquivalent: "")
                historyItem.representedObject = info.code // Store the raw code here
                historyItem.target = self
                menu.addItem(historyItem)
            }
            menu.addItem(NSMenuItem.separator())
        }

        // --- Control Section ---
        let fetchMenuItem = NSMenuItem(title: "Fetch Last OTP Manually", action: #selector(fetchLastOTPManual), keyEquivalent: "F")
        fetchMenuItem.target = self
        menu.addItem(fetchMenuItem)

        menu.addItem(NSMenuItem.separator())
        
        let quitMenuItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitMenuItem.target = self
        menu.addItem(quitMenuItem)

        statusItem?.menu = menu
    }

    // Action for when a user clicks a code in the history.
    @objc func copyHistoryItem(_ sender: NSMenuItem) {
        // NEW: Get the code from the representedObject to avoid parsing the title string.
        if let code = sender.representedObject as? String {
            copyToClipboard(text: code)
            NSSound(named: "Submarine")?.play()
            print("Copied \(code) from history.")
        }
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
        self.lastCheckedMessageID = fetchLastMessageID()
        print("Initialized OTPManager. Last message ID: \(self.lastCheckedMessageID)")
    }

    func startMonitoring(onUpdate: @escaping () -> Void) {
        self.onUpdate = onUpdate
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.fetchLastOTP()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func fetchLastMessageID() -> Int {
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
        do {
            let db = try Connection(dbPath, readonly: true)
            
            // FIX: Define tables and columns for the corrected query.
            let messageTable = Table("message")
            let handleTable = Table("handle")

            let textCol = Expression<String?>("text")
            let handleIdCol = Expression<Int>("handle_id") // This column is on the message table itself.
            let dateCol = Expression<Int>("date")
            let handleIdStringCol = Expression<String>("id")
            let rowid = Expression<Int>("ROWID")

            // FIX: This query now directly joins the message and handle tables.
            let query = messageTable
                .join(handleTable, on: messageTable[handleIdCol] == handleTable[rowid])
                .select(messageTable[textCol], handleTable[handleIdStringCol], messageTable[dateCol])
                .filter(messageTable[rowid] > lastCheckedMessageID)
                .order(messageTable[rowid].desc)

            var otpInfoFound: OTPInfo?

            // FIX: More robust logic for updating the last checked message ID.
            // 1. Get the absolute newest message ID before we start.
            let newestIdInDb = fetchLastMessageID()

            // 2. Loop through the new messages to find an OTP.
            for message in try db.prepare(query) {
                if let text = message[messageTable[textCol]] {
                    if let code = self.extractOTP(from: text) {
                        let sender = message[handleTable[handleIdStringCol]]
                        let appleEpoch = message[messageTable[dateCol]]
                        let unixEpoch = Double(appleEpoch) / 1_000_000_000 + 978307200
                        let date = Date(timeIntervalSince1970: unixEpoch)
                        
                        otpInfoFound = OTPInfo(code: code, sender: sender, date: date)
                        break // Stop after finding the first OTP.
                    }
                }
            }
            
            // 3. After checking, update our high-water mark to the newest ID in the database.
            // This ensures we don't re-check messages we've already seen.
            if newestIdInDb > self.lastCheckedMessageID {
                self.lastCheckedMessageID = newestIdInDb
            }

            // 4. If we found an OTP, process it.
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
        let pattern = #"(?:\b|is: |code is |G-|is )\d{3}[- ]?\d{2,5}\b"#
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            
            if let match = regex.firstMatch(in: text, options: [], range: range) {
                if let swiftRange = Range(match.range, in: text) {
                    let matchedString = String(text[swiftRange])
                    let digitsOnly = matchedString.filter { "0123456789".contains($0) }
                    if (5...8).contains(digitsOnly.count) {
                        return digitsOnly
                    }
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
