//
//  RandomNumberTabView.swift
//  TaskCore
//
//  Created by James Trujillo on 5/2/25.
//

import SwiftUI

struct RandomNumberTabView: View {
    @Binding var randomNumber: Int
    @Binding var maxNumber: Int
    @FocusState private var isTextFieldFocused: Bool
    @State private var isRolling = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background tap area to dismiss keyboard
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        dismissKeyboard()
                    }
                
                VStack(spacing: 30) {
                    // Number Display
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 250, height: 250)
                            .scaleEffect(isRolling ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: isRolling)
                        
                        Text("\(randomNumber)")
                            .font(.system(size: 80, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                            .id(randomNumber) // Forces animation refresh
                            .transition(.scale.combined(with: .opacity))
                            .rotationEffect(.degrees(isRolling ? 360 : 0))
                            .animation(.easeInOut(duration: 0.5), value: isRolling)
                    }
                    .padding()
                    .onTapGesture {
                        dismissKeyboard()
                    }
                    
                    // Controls
                    VStack(spacing: 20) {
                        HStack {
                            Text("Maximum Number:")
                                .font(.title2)
                            TextField("Max", value: $maxNumber, format: .number)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 100)
                                .keyboardType(.numberPad)
                                .focused($isTextFieldFocused)
                                .onSubmit {
                                    dismissKeyboard()
                                }
                                // Add haptic when changing max number
                                .onChange(of: maxNumber) { _, _ in
                                    HapticManager.shared.selection()
                                }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(15)
                        .onTapGesture { }  // Prevent background tap from triggering on this area
                        
                        Button(action: generateRandomNumberWithHaptics) {
                            Label("Generate", systemImage: "dice")
                                .font(.title2)
                                .frame(width: 200)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(15)
                        }
                        .disabled(isRolling)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Random Number")
        }
    }
    
    private func dismissKeyboard() {
        isTextFieldFocused = false
        // Force hide keyboard immediately
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func generateRandomNumberWithHaptics() {
        dismissKeyboard()
        
        // Start rolling animation
        withAnimation {
            isRolling = true
        }
        
        // Create dice rolling haptic effect
        let impactCount = 5
        for i in 0..<impactCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) {
                // Decreasing intensity
                let intensity = CGFloat(impactCount - i) / CGFloat(impactCount)
                HapticManager.shared.impact(style: .light, intensity: intensity * 0.8)
            }
        }
        
        // Generate number and stop animation after haptics
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            HapticManager.shared.success()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0)) {
                randomNumber = Int.random(in: 1...maxNumber)
                isRolling = false
            }
        }
    }
}
