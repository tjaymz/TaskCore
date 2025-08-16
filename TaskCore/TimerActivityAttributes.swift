//
//  TimerActivityAttributes.swift
//  TaskCore
//
//  Created by James Trujillo on 8/7/25.
//


//
//  TimerActivityAttributes.swift
//  TaskCore
//
//  Created by James Trujillo on 5/2/25.
//

import Foundation
import ActivityKit

struct TimerActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic values that update during the activity
        var endTime: Date
        var totalDuration: Int // in seconds
        var isPaused: Bool
    }
    
    // Static values that don't change during the activity
    var timerName: String
}