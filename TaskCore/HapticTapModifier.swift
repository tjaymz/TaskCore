//
//  HapticTapModifier.swift
//  TaskCore
//
//  Created by James Trujillo on 8/7/25.
//


import SwiftUI

// View modifier for tap haptics
struct HapticTapModifier: ViewModifier {
    let style: UIImpactFeedbackGenerator.FeedbackStyle
    let intensity: CGFloat
    
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                HapticManager.shared.impact(style: style, intensity: intensity)
            }
    }
}

// View modifier for button haptics
struct HapticButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                TapGesture()
                    .onEnded { _ in
                        HapticManager.shared.tap()
                    }
            )
    }
}

// View modifier for toggle haptics
struct HapticToggleModifier: ViewModifier {
    @Binding var isOn: Bool
    
    func body(content: Content) -> some View {
        content
            .onChange(of: isOn) { _, _ in
                HapticManager.shared.selection()
            }
    }
}

// Extension to make modifiers easier to use
extension View {
    func hapticTap(style: UIImpactFeedbackGenerator.FeedbackStyle = .light, intensity: CGFloat = 0.6) -> some View {
        modifier(HapticTapModifier(style: style, intensity: intensity))
    }
    
    func hapticButton() -> some View {
        modifier(HapticButtonModifier())
    }
    
    func hapticToggle(isOn: Binding<Bool>) -> some View {
        modifier(HapticToggleModifier(isOn: isOn))
    }
    
    func hapticFeedback(_ type: UINotificationFeedbackGenerator.FeedbackType, trigger: some Equatable) -> some View {
        self.onChange(of: trigger) { _, _ in
            HapticManager.shared.notification(type: type)
        }
    }
}