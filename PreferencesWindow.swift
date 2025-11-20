//
//  PreferencesWindow.swift
//  OTPExtractor
//
//  Created by Error
//

import SwiftUI

/// Preferences window for configuring app settings
struct PreferencesView: View {
    @State private var pollingInterval: Double
    @State private var maxHistorySize: Int
    @State private var autoClipboardClear: Bool
    @State private var clipboardClearDelay: Double
    @State private var notificationsEnabled: Bool
    @State private var soundEnabled: Bool

    private let prefs = PreferencesManager.shared

    init() {
        _pollingInterval = State(initialValue: PreferencesManager.shared.pollingInterval)
        _maxHistorySize = State(initialValue: PreferencesManager.shared.maxHistorySize)
        _autoClipboardClear = State(initialValue: PreferencesManager.shared.autoClipboardClear)
        _clipboardClearDelay = State(initialValue: PreferencesManager.shared.clipboardClearDelay)
        _notificationsEnabled = State(initialValue: PreferencesManager.shared.notificationsEnabled)
        _soundEnabled = State(initialValue: PreferencesManager.shared.soundEnabled)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("OTP Extractor Preferences")
                .font(.title2)
                .fontWeight(.bold)

            GroupBox(label: Text("Monitoring")) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Polling Interval:")
                        Slider(value: $pollingInterval, in: 1...30, step: 1)
                        Text("\(Int(pollingInterval))s")
                            .frame(width: 35)
                    }
                    Text("How often to check for new OTP messages")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 5)
            }

            GroupBox(label: Text("History")) {
                VStack(alignment: .leading, spacing: 10) {
                    Stepper(value: $maxHistorySize, in: 1...10) {
                        Text("Keep last \(maxHistorySize) codes")
                    }
                    Text("Number of recent OTP codes to display in menu")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 5)
            }

            GroupBox(label: Text("Security")) {
                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Auto-clear clipboard", isOn: $autoClipboardClear)

                    if autoClipboardClear {
                        HStack {
                            Text("Clear after:")
                            Slider(value: $clipboardClearDelay, in: 10...300, step: 10)
                            Text("\(Int(clipboardClearDelay))s")
                                .frame(width: 40)
                        }
                        .padding(.leading, 20)
                    }

                    Text("Automatically clear clipboard after specified time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 5)
            }

            GroupBox(label: Text("Notifications")) {
                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Show notifications", isOn: $notificationsEnabled)
                    Toggle("Play sound", isOn: $soundEnabled)

                    Text("Alert when an OTP code is detected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 5)
            }

            Divider()

            HStack {
                Button("Reset to Defaults") {
                    resetToDefaults()
                }

                Spacer()

                Button("Close") {
                    saveAndClose()
                }
                .keyboardShortcut(.defaultAction)
            }

            Text("Version \(Constants.appVersion)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .frame(width: 450)
    }

    private func resetToDefaults() {
        prefs.resetToDefaults()
        pollingInterval = prefs.pollingInterval
        maxHistorySize = prefs.maxHistorySize
        autoClipboardClear = prefs.autoClipboardClear
        clipboardClearDelay = prefs.clipboardClearDelay
        notificationsEnabled = prefs.notificationsEnabled
        soundEnabled = prefs.soundEnabled
    }

    private func saveAndClose() {
        prefs.pollingInterval = pollingInterval
        prefs.maxHistorySize = maxHistorySize
        prefs.autoClipboardClear = autoClipboardClear
        prefs.clipboardClearDelay = clipboardClearDelay
        prefs.notificationsEnabled = notificationsEnabled
        prefs.soundEnabled = soundEnabled

        // Notify the app to reload settings
        NotificationCenter.default.post(name: Notification.Name("PreferencesChanged"), object: nil)

        // Close the window
        NSApplication.shared.keyWindow?.close()
    }
}

#Preview {
    PreferencesView()
}
