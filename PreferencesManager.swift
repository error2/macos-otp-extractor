//
//  PreferencesManager.swift
//  OTPExtractor
//
//  Created by Error
//

import Foundation

/// Manages user preferences and settings
class PreferencesManager {
    static let shared = PreferencesManager()

    private let defaults = UserDefaults.standard

    private init() {
        registerDefaults()
    }

    /// Register default values for all preferences
    private func registerDefaults() {
        defaults.register(defaults: [
            Constants.UserDefaultsKeys.pollingInterval: Constants.pollingInterval,
            Constants.UserDefaultsKeys.maxHistorySize: Constants.defaultMaxHistorySize,
            Constants.UserDefaultsKeys.autoClipboardClear: true,
            Constants.UserDefaultsKeys.clipboardClearDelay: Constants.clipboardClearDelay,
            Constants.UserDefaultsKeys.notificationsEnabled: true,
            Constants.UserDefaultsKeys.soundEnabled: true
        ])
    }

    // MARK: - Polling Interval

    var pollingInterval: TimeInterval {
        get { defaults.double(forKey: Constants.UserDefaultsKeys.pollingInterval) }
        set { defaults.set(newValue, forKey: Constants.UserDefaultsKeys.pollingInterval) }
    }

    // MARK: - History

    var maxHistorySize: Int {
        get { defaults.integer(forKey: Constants.UserDefaultsKeys.maxHistorySize) }
        set { defaults.set(newValue, forKey: Constants.UserDefaultsKeys.maxHistorySize) }
    }

    // MARK: - Clipboard

    var autoClipboardClear: Bool {
        get { defaults.bool(forKey: Constants.UserDefaultsKeys.autoClipboardClear) }
        set { defaults.set(newValue, forKey: Constants.UserDefaultsKeys.autoClipboardClear) }
    }

    var clipboardClearDelay: TimeInterval {
        get { defaults.double(forKey: Constants.UserDefaultsKeys.clipboardClearDelay) }
        set { defaults.set(newValue, forKey: Constants.UserDefaultsKeys.clipboardClearDelay) }
    }

    // MARK: - Notifications

    var notificationsEnabled: Bool {
        get { defaults.bool(forKey: Constants.UserDefaultsKeys.notificationsEnabled) }
        set { defaults.set(newValue, forKey: Constants.UserDefaultsKeys.notificationsEnabled) }
    }

    var soundEnabled: Bool {
        get { defaults.bool(forKey: Constants.UserDefaultsKeys.soundEnabled) }
        set { defaults.set(newValue, forKey: Constants.UserDefaultsKeys.soundEnabled) }
    }

    /// Reset all preferences to default values
    func resetToDefaults() {
        let domain = Bundle.main.bundleIdentifier!
        defaults.removePersistentDomain(forName: domain)
        registerDefaults()
    }
}
