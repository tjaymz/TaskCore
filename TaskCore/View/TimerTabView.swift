//
//  TimerTabView.swift
//  TaskCore
//
//  Created by James Trujillo on 5/2/25.
//

import SwiftUI
import UserNotifications
import ActivityKit

struct TimerTabView: View {
    @Binding var timeRemaining: Int
    @Binding var selectedMinutes: Int
    @Binding var isTimerRunning: Bool
    @Binding var timer: Timer?
    
    @StateObject private var todoManager = TodoManager()
    @StateObject private var liveActivityManager = LiveActivityManager.shared
    @State private var isFlashing = false
    @State private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("liveActivitiesEnabled") private var liveActivitiesEnabled = true
    
    // Timer options in 15-second increments
    struct TimerOption {
        let seconds: Int
        let minutes: Int // For compatibility with existing binding
        let display: String
    }
    
    private var timerOptions: [TimerOption] {
        var options: [TimerOption] = []
        
        // 15 second increments from 15 seconds to 5 minutes
        for i in 1...20 { // 15s, 30s, 45s, 1m, 1m15s, ... 5m
            let totalSeconds = i * 15
            let mins = totalSeconds / 60
            let secs = totalSeconds % 60
            
            let display: String
            if totalSeconds < 60 {
                display = "\(totalSeconds)s"
            } else if secs == 0 {
                display = "\(mins)m"
            } else {
                display = "\(mins)m \(secs)s"
            }
            
            // Convert to "minutes" for compatibility (storing as fractional minutes)
            let fractionalMinutes = Int(round(Double(totalSeconds) / 60.0 * 4)) // Store as quarter-minutes
            
            options.append(TimerOption(
                seconds: totalSeconds,
                minutes: fractionalMinutes,
                display: display
            ))
        }
        
        // Add longer intervals (6m, 7m, 8m, 9m, 10m, then 5-minute increments up to 60m)
        for mins in [6, 7, 8, 9, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60] {
            options.append(TimerOption(
                seconds: mins * 60,
                minutes: mins * 4, // Store as quarter-minutes for consistency
                display: "\(mins)m"
            ))
        }
        
        return options
    }
    
    // Convert selectedMinutes back to actual seconds
    private var selectedSeconds: Int {
        if let option = timerOptions.first(where: { $0.minutes == selectedMinutes }) {
            return option.seconds
        }
        // Fallback for legacy values
        return max(1, selectedMinutes / 4) * 60
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Timer Display
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        .frame(width: 250, height: 250)
                    
                    // Flashing red background for last 5 seconds
                    if timeRemaining <= 5 && timeRemaining > 0 && isTimerRunning {
                        Circle()
                            .fill(Color.red.opacity(isFlashing ? 0.3 : 0.1))
                            .frame(width: 234, height: 234) // Slightly smaller to fit inside the stroke
                            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isFlashing)
                    }
                    
                    // Progress circle
                    Circle()
                        .trim(from: 0, to: timeRemaining > 0 ? CGFloat(timeRemaining) / CGFloat(selectedSeconds) : 0)
                        .stroke(
                            timeRemaining <= 5 && timeRemaining > 0 && isTimerRunning ? Color.red : (isTimerRunning ? Color.green : Color.blue),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 250, height: 250)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear, value: timeRemaining)
                    
                    // Timer text
                    VStack {
                        Text("\(timeRemaining)")
                            .font(.system(size: 80, weight: .bold, design: .rounded))
                            .foregroundColor(
                                timeRemaining <= 5 && timeRemaining > 0 && isTimerRunning ?
                                Color.red : (isTimerRunning ? .green : .primary)
                            )
                            .animation(.easeInOut(duration: 0.2), value: timeRemaining)
                        Text("seconds")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                // Haptic feedback for timer events
                .onChange(of: timeRemaining) { oldValue, newValue in
                    // Haptic tick for last 5 seconds
                    if newValue <= 5 && newValue > 0 && isTimerRunning {
                        HapticManager.shared.tick()
                    }
                    
                    // Success haptic when timer completes
                    if oldValue > 0 && newValue == 0 && isTimerRunning {
                        HapticManager.shared.success()
                        // End Live Activity
                        if liveActivitiesEnabled {
                            liveActivityManager.endCurrentActivity()
                        }
                        // Only send notification if enabled
                        if notificationsEnabled {
                            sendTimerCompleteNotification()
                        }
                    }
                }
                .onChange(of: isTimerRunning) { _, newValue in
                    if !newValue {
                        stopFlashing()
                    }
                }
                .onChange(of: timeRemaining) { _, newValue in
                    if newValue <= 5 && newValue > 0 && isTimerRunning {
                        if !isFlashing {
                            startFlashing()
                        }
                    } else if isFlashing && (newValue > 5 || newValue == 0) {
                        stopFlashing()
                    }
                }
                
                // Timer Controls
                VStack(spacing: 20) {
                    HStack {
                        Text("Set Timer:")
                            .font(.title2)
                        Picker("Time", selection: $selectedMinutes) {
                            ForEach(timerOptions, id: \.seconds) { option in
                                Text(option.display).tag(option.minutes)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 150)
                        .disabled(isTimerRunning)
                        // Haptic feedback when changing timer duration
                        .onChange(of: selectedMinutes) { _, _ in
                            if !isTimerRunning {
                                HapticManager.shared.selection()
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(15)
                    
                    Button(action: {
                        // Haptic feedback for start/stop
                        if isTimerRunning {
                            HapticManager.shared.warning()
                        } else {
                            HapticManager.shared.tap()
                        }
                        toggleTimer()
                    }) {
                        Text(isTimerRunning ? "Stop" : "Start")
                            .font(.title)
                            .frame(width: 200)
                            .padding()
                            .background(isTimerRunning ? Color.red : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }
                    
                    // Reset button when timer is stopped
                    if !isTimerRunning && timeRemaining != selectedSeconds {
                        Button(action: {
                            HapticManager.shared.tap()
                            resetTimer()
                        }) {
                            Text("Reset")
                                .font(.title2)
                                .frame(width: 150)
                                .padding(.vertical, 10)
                                .background(Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }
                
                // Show Live Activity status if available
                if isTimerRunning && liveActivitiesEnabled && liveActivityManager.currentActivity != nil {
                    HStack {
                        Image(systemName: "dot.radiowaves.left.and.right")
                            .foregroundColor(.green)
                        Text("Live Activity active")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
                
                // Show notification status if timer is running
                if isTimerRunning && !notificationsEnabled {
                    HStack {
                        Image(systemName: "bell.slash")
                            .foregroundColor(.orange)
                        Text("Notifications disabled")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
            .navigationTitle("Timer")
        }
        .onAppear {
            checkForActiveTimer()
            requestLiveActivityPermission()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            saveTimerState()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            checkForActiveTimer()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            checkForActiveTimer()
        }
        // Listen for notification setting changes
        .onChange(of: notificationsEnabled) { _, newValue in
            if !newValue {
                // Cancel any pending notifications if disabled
                cancelTimerNotifications()
            } else if isTimerRunning && timeRemaining > 0 {
                // Reschedule notification if enabled and timer is running
                scheduleTimerNotification(seconds: timeRemaining)
            }
        }
    }
    
    private func requestLiveActivityPermission() {
        if #available(iOS 16.2, *) {
            Task {
                let info = ActivityAuthorizationInfo()
                if !info.areActivitiesEnabled {
                    print("Live Activities are not enabled. User needs to enable in Settings.")
                }
            }
        }
    }
    
    private func startFlashing() {
        isFlashing = true
    }
    
    private func stopFlashing() {
        isFlashing = false
    }
    
    private func resetTimer() {
        timeRemaining = selectedSeconds
        stopFlashing()
        todoManager.clearTimerState()
        cancelTimerNotifications()
        // End Live Activity
        if liveActivitiesEnabled {
            liveActivityManager.endCurrentActivity()
        }
    }
    
    private func saveTimerState() {
        if isTimerRunning && timeRemaining > 0 {
            let endDate = Date().addingTimeInterval(TimeInterval(timeRemaining))
            todoManager.saveTimerState(endDate: endDate, duration: selectedSeconds)
            
            // Update Live Activity
            if liveActivitiesEnabled && liveActivityManager.currentActivity != nil {
                liveActivityManager.updateTimerActivity(endTime: endDate, isPaused: false)
            }
            
            // Only schedule notification if enabled
            if notificationsEnabled {
                scheduleTimerNotification(seconds: timeRemaining)
            } else {
                // Make sure to cancel any existing notifications if disabled
                cancelTimerNotifications()
            }
        } else {
            todoManager.clearTimerState()
            cancelTimerNotifications()
            // End Live Activity
            if liveActivitiesEnabled {
                liveActivityManager.endCurrentActivity()
            }
        }
    }
    
    private func checkForActiveTimer() {
        // Check if we have a saved timer
        if let endDate = todoManager.timerEndDate {
            let remaining = Int(endDate.timeIntervalSinceNow)
            
            if remaining > 0 {
                // Timer is still active
                timeRemaining = remaining
                // Find the closest matching duration in our options
                let savedDuration = todoManager.timerDuration
                if let matchingOption = timerOptions.first(where: { $0.seconds == savedDuration }) {
                    selectedMinutes = matchingOption.minutes
                }
                
                // Resume the timer
                if !isTimerRunning {
                    isTimerRunning = true
                    startTimerCountdown()
                    
                    // Resume Live Activity
                    if liveActivitiesEnabled {
                        liveActivityManager.startTimerActivity(duration: savedDuration, endTime: endDate)
                    }
                }
            } else {
                // Timer has expired while app was closed
                timeRemaining = 0
                isTimerRunning = false
                todoManager.clearTimerState()
                cancelTimerNotifications()
                
                // End Live Activity
                if liveActivitiesEnabled {
                    liveActivityManager.endCurrentActivity()
                }
                
                // Show completion feedback
                HapticManager.shared.success()
            }
        }
    }
    
    private func startTimerCountdown() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
                
                // Update saved end date periodically
                if timeRemaining % 5 == 0 {
                    saveTimerState()
                }
            } else {
                timer?.invalidate()
                timer = nil
                isTimerRunning = false
                stopFlashing()
                todoManager.clearTimerState()
                cancelTimerNotifications()
                
                // End Live Activity
                if liveActivitiesEnabled {
                    liveActivityManager.endCurrentActivity()
                }
            }
        }
    }
    
    func toggleTimer() {
        if isTimerRunning {
            // Stop timer
            timer?.invalidate()
            timer = nil
            isTimerRunning = false
            stopFlashing()
            todoManager.clearTimerState()
            cancelTimerNotifications()
            
            // End Live Activity
            if liveActivitiesEnabled {
                liveActivityManager.endCurrentActivity()
            }
        } else {
            // Start timer
            if timeRemaining == 0 {
                timeRemaining = selectedSeconds
            }
            isTimerRunning = true
            
            // Save the end date
            let endDate = Date().addingTimeInterval(TimeInterval(timeRemaining))
            todoManager.saveTimerState(endDate: endDate, duration: selectedSeconds)
            
            // Start Live Activity
            if liveActivitiesEnabled {
                liveActivityManager.startTimerActivity(duration: selectedSeconds, endTime: endDate)
            }
            
            // Only schedule notification if enabled
            if notificationsEnabled {
                scheduleTimerNotification(seconds: timeRemaining)
            }
            
            // Start countdown
            startTimerCountdown()
        }
    }
    
    // MARK: - Notifications (keeping existing notification code)
    
    private func scheduleTimerNotification(seconds: Int) {
        // Check if notifications are enabled before scheduling
        guard notificationsEnabled else {
            print("Notifications disabled - not scheduling timer notification")
            return
        }
        
        // First check if we have permission
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else {
                print("Notification permission not granted")
                return
            }
            
            // Cancel existing notifications
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["TimerComplete"])
            
            let content = UNMutableNotificationContent()
            content.title = "Timer Complete!"
            content.body = "Your \(formatTime(seconds)) timer has finished."
            content.sound = .default
            
            // Set badge using new API
            if #available(iOS 17.0, *) {
                UNUserNotificationCenter.current().setBadgeCount(1)
            } else {
                content.badge = 1
            }
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
            let request = UNNotificationRequest(identifier: "TimerComplete", content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error)")
                } else {
                    print("Notification scheduled for \(seconds) seconds")
                }
            }
        }
    }
    
    private func cancelTimerNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["TimerComplete", "TimerCompleteImmediate"])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["TimerComplete", "TimerCompleteImmediate"])
        
        // Clear badge using new API
        if #available(iOS 17.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(0)
        } else {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
    
    private func sendTimerCompleteNotification() {
        // Check if notifications are enabled before sending
        guard notificationsEnabled else {
            print("Notifications disabled - not sending completion notification")
            return
        }
        
        // First check if we have permission
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else {
                print("Notification permission not granted")
                return
            }
            
            // If app is in background, this will show immediately
            let content = UNMutableNotificationContent()
            content.title = "Timer Complete!"
            content.body = "Your timer has finished."
            content.sound = .default
            
            // Set badge using new API
            if #available(iOS 17.0, *) {
                UNUserNotificationCenter.current().setBadgeCount(1)
            } else {
                content.badge = 1
            }
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
            let request = UNNotificationRequest(identifier: "TimerCompleteImmediate", content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error sending immediate notification: \(error)")
                } else {
                    print("Immediate notification sent")
                }
            }
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        } else {
            let mins = seconds / 60
            let secs = seconds % 60
            if secs == 0 {
                return "\(mins)m"
            } else {
                return "\(mins)m \(secs)s"
            }
        }
    }
}
