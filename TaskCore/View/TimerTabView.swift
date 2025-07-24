//
//  TimerTabView.swift
//  TaskCore
//
//  Created by James Trujillo on 5/2/25.
//

import SwiftUI

struct TimerTabView: View {
    @Binding var timeRemaining: Int
    @Binding var selectedMinutes: Int
    @Binding var isTimerRunning: Bool
    @Binding var timer: Timer?
    
    @State private var isFlashing = false
    
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

                .onChange(of: isTimerRunning) {
                    if !isTimerRunning {
                        stopFlashing()
                    }
                }
                .onChange(of: timeRemaining) {
                    if timeRemaining <= 5 && timeRemaining > 0 && isTimerRunning {
                        if !isFlashing {
                            startFlashing()
                        }
                    } else if isFlashing && (timeRemaining > 5 || timeRemaining == 0) {
                        stopFlashing()
                    }
                }
                
                // Timer Controls
                VStack(spacing: 20) {
                    HStack {
                        Text("Set Timer:")
                            .font(.title2)
                        Picker("Time", selection: $selectedMinutes) {
                            // 15 second increments from 15 seconds to 60 minutes
                            ForEach(timerOptions, id: \.seconds) { option in
                                Text(option.display).tag(option.minutes)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 150)
                        .disabled(isTimerRunning)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(15)
                    
                    Button(action: toggleTimer) {
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
                        Button(action: resetTimer) {
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
            }
            .padding()
            .navigationTitle("Timer")
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
    }
    
    func toggleTimer() {
        if isTimerRunning {
            timer?.invalidate()
            timer = nil
            isTimerRunning = false
            stopFlashing()
        } else {
            if timeRemaining == 0 {
                timeRemaining = selectedSeconds
            }
            isTimerRunning = true
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    timer?.invalidate()
                    timer = nil
                    isTimerRunning = false
                    stopFlashing()
                }
            }
        }
    }
}
