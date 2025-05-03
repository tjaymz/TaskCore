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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Number Display
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 250, height: 250)
                    
                    Text("\(randomNumber)")
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                        .id(randomNumber) // Forces animation refresh
                        .transition(.scale.combined(with: .opacity))
                }
                .padding()
                
                // Controls
                VStack(spacing: 20) {
                    HStack {
                        Text("Maximum Number:")
                            .font(.title2)
                        TextField("Max", value: $maxNumber, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 100)
                            .keyboardType(.numberPad)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(15)
                    
                    Button(action: generateRandomNumber) {
                        Label("Generate", systemImage: "dice")
                            .font(.title2)
                            .frame(width: 200)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }
                }
            }
            .padding()
            .navigationTitle("Random Number")
        }
    }
    
    func generateRandomNumber() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0)) {
            randomNumber = Int.random(in: 1...maxNumber)
        }
    }
}
