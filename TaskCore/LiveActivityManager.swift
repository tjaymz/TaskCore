//
//  LiveActivityManager.swift
//  TaskCore
//
//  Created by James Trujillo on 5/2/25.
//

import Foundation
import ActivityKit
import SwiftUI

class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()
    
    @Published var currentActivity: Activity<TimerActivityAttributes>?
    
    private init() {}
    
    func startTimerActivity(duration: Int, endTime: Date) {
        // Check if Live Activities are available
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not enabled")
            return
        }
        
        // End any existing activity
        endCurrentActivity()
        
        let attributes = TimerActivityAttributes(timerName: "Timer")
        let contentState = TimerActivityAttributes.ContentState(
            endTime: endTime,
            totalDuration: duration,
            isPaused: false
        )
        
        let activityContent = ActivityContent(state: contentState, staleDate: endTime)
        
        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: activityContent,
                pushType: nil
            )
            print("Started Live Activity with ID: \(currentActivity?.id ?? "unknown")")
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }
    
    func updateTimerActivity(endTime: Date, isPaused: Bool) {
        guard let activity = currentActivity else { return }
        
        Task {
            let contentState = TimerActivityAttributes.ContentState(
                endTime: endTime,
                totalDuration: activity.content.state.totalDuration,
                isPaused: isPaused
            )
            
            let activityContent = ActivityContent(state: contentState, staleDate: endTime)
            
            await activity.update(activityContent)
            print("Updated Live Activity")
        }
    }
    
    func endCurrentActivity() {
        guard let activity = currentActivity else { return }
        
        Task {
            let finalContent = TimerActivityAttributes.ContentState(
                endTime: Date(),
                totalDuration: activity.content.state.totalDuration,
                isPaused: false
            )
            
            await activity.end(
                ActivityContent(state: finalContent, staleDate: .now),
                dismissalPolicy: .immediate
            )
            
            await MainActor.run {
                currentActivity = nil
            }
            print("Ended Live Activity")
        }
    }
    
    func cancelActivity() {
        endCurrentActivity()
    }
}