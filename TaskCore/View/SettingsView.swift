//
//  SettingsView.swift
//  TaskCore
//
//  Created by James Trujillo on 8/7/25.
//


//
//  SettingsView.swift
//  TaskCore
//
//  Created by James Trujillo on 5/2/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("liveActivitiesEnabled") private var liveActivitiesEnabled = true
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Haptic Feedback") {
                    Toggle("Enable Haptics", isOn: $hapticsEnabled)
                        .onChange(of: hapticsEnabled) { _, newValue in
                            if newValue {
                                HapticManager.shared.selection()
                            }
                        }
                    
                    if hapticsEnabled {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Test Haptic Feedback")
                                .font(.headline)
                                .padding(.top, 5)
                            
                            HStack(spacing: 10) {
                                Button("Light") {
                                    HapticManager.shared.impact(style: .light)
                                }
                                .buttonStyle(.bordered)
                                
                                Button("Medium") {
                                    HapticManager.shared.impact(style: .medium)
                                }
                                .buttonStyle(.bordered)
                                
                                Button("Heavy") {
                                    HapticManager.shared.impact(style: .heavy)
                                }
                                .buttonStyle(.bordered)
                            }
                            
                            HStack(spacing: 10) {
                                Button("Success") {
                                    HapticManager.shared.success()
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.green)
                                
                                Button("Warning") {
                                    HapticManager.shared.warning()
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.orange)
                                
                                Button("Error") {
                                    HapticManager.shared.error()
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.red)
                            }
                            
                            Text("Dice Roll Effect")
                                .font(.headline)
                                .padding(.top, 5)
                            
                            Button("Test Dice Roll") {
                                // Simulate dice roll haptic pattern
                                let impactCount = 5
                                for i in 0..<impactCount {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) {
                                        let intensity = CGFloat(impactCount - i) / CGFloat(impactCount)
                                        HapticManager.shared.impact(style: .light, intensity: intensity * 0.8)
                                    }
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                    HapticManager.shared.success()
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.vertical, 5)
                    }
                }
                
                Section("Audio") {
                    Toggle("Enable Sounds", isOn: $soundEnabled)
                }
                
                Section("Notifications") {
                    Toggle("Timer Notifications", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, newValue in
                            if newValue {
                                requestNotificationPermission()
                            }
                        }
                    
                    if notificationsEnabled {
                        Text("You'll receive notifications when timers complete while the app is in the background")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("1")
                            .foregroundColor(.secondary)
                    }
                    
                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                    
                    Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                }
                
                Section {
                    Button("Rate TaskCore") {
                        // Open App Store review
                        if let url = URL(string: "https://apps.apple.com/app/idXXXXXXXXX?action=write-review") {
                            UIApplication.shared.open(url)
                        }
                    }
                    
                    Button("Share TaskCore") {
                        // Share sheet functionality would go here
                    }
                }
                
                Section("Live Activities") {
                    Toggle("Enable Live Activities", isOn: $liveActivitiesEnabled)
                        .onChange(of: liveActivitiesEnabled) { _, newValue in
                            if newValue {
                                HapticManager.shared.selection()
                            } else {
                                // End any active Live Activity if disabled
                                LiveActivityManager.shared.endCurrentActivity()
                            }
                        }
                    
                    if liveActivitiesEnabled {
                        Text("Shows timer countdown in Dynamic Island and on Lock Screen")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if !granted {
                DispatchQueue.main.async {
                    notificationsEnabled = false
                }
            }
        }
    }
}
