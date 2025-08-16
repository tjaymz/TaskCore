//
//  HapticManager.swift
//  TaskCore
//
//  Created by James Trujillo on 8/7/25.
//


import SwiftUI

class HapticManager {
    static let shared = HapticManager()
    
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    
    private init() {}
    
    // Simple impact variations
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium, intensity: CGFloat = 1.0) {
        guard hapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred(intensity: intensity)
    }
    
    // Notification haptics
    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        guard hapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
    
    // Selection haptic
    func selection() {
        guard hapticsEnabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }
    
    // Timer tick
    func tick() {
        impact(style: .light, intensity: 0.3)
    }
    
    // Button tap
    func tap() {
        impact(style: .light, intensity: 0.6)
    }
    
    // Success action
    func success() {
        notification(type: .success)
    }
    
    // Warning action
    func warning() {
        notification(type: .warning)
    }
    
    // Error action
    func error() {
        notification(type: .error)
    }
}