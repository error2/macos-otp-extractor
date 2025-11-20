//
//  ClipboardManager.swift
//  OTPExtractor
//
//  Created by Error
//

import AppKit
import os.log

/// Manages clipboard operations with security features
class ClipboardManager {
    static let shared = ClipboardManager()

    private var clearTimer: Timer?
    private var lastCopiedText: String?
    private let logger = Logger(subsystem: "com.error.OTPExtractor", category: "Clipboard")

    private init() {}

    /// Copies text to clipboard with optional auto-clear feature
    /// - Parameters:
    ///   - text: The text to copy
    ///   - autoClear: Whether to automatically clear the clipboard after a delay
    ///   - delay: The delay before clearing (defaults to Constants.clipboardClearDelay)
    func copy(text: String, autoClear: Bool = true, delay: TimeInterval = Constants.clipboardClearDelay) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        lastCopiedText = text
        logger.log("Text copied to clipboard (length: \(text.count))")

        // Cancel any existing timer
        clearTimer?.invalidate()

        // Set up auto-clear if enabled
        if autoClear && UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.autoClipboardClear) {
            let clearDelay = UserDefaults.standard.double(forKey: Constants.UserDefaultsKeys.clipboardClearDelay)
            let actualDelay = clearDelay > 0 ? clearDelay : delay

            clearTimer = Timer.scheduledTimer(withTimeInterval: actualDelay, repeats: false) { [weak self] _ in
                self?.clearIfUnchanged()
            }
            logger.log("Auto-clear scheduled for \(actualDelay) seconds")
        }
    }

    /// Clears the clipboard only if it still contains the last copied OTP
    private func clearIfUnchanged() {
        guard let lastText = lastCopiedText else { return }

        let pasteboard = NSPasteboard.general
        if let currentText = pasteboard.string(forType: .string), currentText == lastText {
            pasteboard.clearContents()
            logger.log("Clipboard auto-cleared")
        } else {
            logger.log("Clipboard content changed by user, skipping auto-clear")
        }

        lastCopiedText = nil
    }

    /// Manually cancels the auto-clear timer
    func cancelAutoClear() {
        clearTimer?.invalidate()
        clearTimer = nil
        logger.log("Auto-clear cancelled")
    }
}
