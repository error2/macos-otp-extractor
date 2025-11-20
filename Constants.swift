//
//  Constants.swift
//  OTPExtractor
//
//  Created by Error
//

import Foundation

/// Application-wide constants
enum Constants {
    // MARK: - Time Constants

    /// Apple epoch offset (seconds between Unix epoch and Apple's reference date)
    static let appleEpochOffset: Double = 978307200.0

    /// Conversion factor from nanoseconds to seconds
    static let nanosecondsToSeconds: Double = 1_000_000_000.0

    /// Database polling interval in seconds
    static let pollingInterval: TimeInterval = 5.0

    /// Clipboard auto-clear delay in seconds
    static let clipboardClearDelay: TimeInterval = 60.0

    /// Animation duration for status icon feedback
    static let statusIconAnimationDuration: TimeInterval = 2.0

    // MARK: - UI Constants

    /// Maximum number of OTP codes to keep in history
    static let defaultMaxHistorySize: Int = 3

    /// App version string
    static let appVersion: String = "1.3.0"

    // MARK: - Database Constants

    /// Relative path to Messages database from home directory
    static let messagesDBPath: String = "Library/Messages/chat.db"

    // MARK: - OTP Pattern Constants

    /// Minimum OTP length (digits)
    static let minOTPLength: Int = 4

    /// Maximum OTP length (digits)
    static let maxOTPLength: Int = 9

    /// Minimum alphanumeric OTP length
    static let minAlphanumericOTPLength: Int = 6

    /// Maximum alphanumeric OTP length
    static let maxAlphanumericOTPLength: Int = 8

    // MARK: - User Defaults Keys

    enum UserDefaultsKeys {
        static let pollingInterval = "pollingInterval"
        static let maxHistorySize = "maxHistorySize"
        static let autoClipboardClear = "autoClipboardClear"
        static let clipboardClearDelay = "clipboardClearDelay"
        static let notificationsEnabled = "notificationsEnabled"
        static let soundEnabled = "soundEnabled"
    }

    // MARK: - Notification Names

    enum Notifications {
        static let otpDetected = NSNotification.Name("OTPDetected")
        static let historyUpdated = NSNotification.Name("HistoryUpdated")
        static let permissionChanged = NSNotification.Name("PermissionChanged")
    }
}
