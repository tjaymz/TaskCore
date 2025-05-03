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
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Timer Display
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        .frame(width: 250, height: 250)
                    
                    Circle()
                        .trim(from: 0, to: timeRemaining > 0 ? CGFloat(timeRemaining) / CGFloat(selectedMinutes * 60) : 0)
                        .stroke(isTimerRunning ? Color.green : Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 250, height: 250)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear, value: timeRemaining)
                    
                    VStack {
                        Text("\(timeRemaining)")
                            .font(.system(size: 80, weight: .bold, design: .rounded))
                            .foregroundColor(isTimerRunning ? .green : .primary)
                        Text("seconds")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                
                // Timer Controls
                VStack(spacing: 20) {
                    HStack {
                        Text("Set Timer:")
                            .font(.title2)
                        Picker("Minutes", selection: $selectedMinutes) {
                            ForEach(1...60, id: \.self) { minute in
                                Text("\(minute) min").tag(minute)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 150)
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
                }
            }
            .padding()
            .navigationTitle("Timer")
        }
    }
    
    func toggleTimer() {
        if isTimerRunning {
            timer?.invalidate()
            timer = nil
            isTimerRunning = false
        } else {
            timeRemaining = selectedMinutes * 60
            isTimerRunning = true
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    timer?.invalidate()
                    timer = nil
                    isTimerRunning = false
                }
            }
        }
    }
}
