//
//  CardioWorkoutView.swift
//  Workout4
//
//  Created by Warren Hansen on 4/9/25.
//

import SwiftUI
import SwiftData

struct CardioWorkoutView: View {
    let group: String
    @Binding var lastWorkoutGroup: String?
    @Binding var totalTimeElapsed: Int  // Binding to master timer
    let cardioStartTime: Int  // Time when cardio phase started
    let onComplete: ((Int) -> Void)?  // Callback with cardio time only
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showEndWorkoutConfirmation = false
    
    var cardioTimeElapsed: Int {
        totalTimeElapsed - cardioStartTime  // Calculate cardio time from master timer
    }
    
    var timeString: String {
        // Display only cardio time
        let minutes = cardioTimeElapsed / 60
        let seconds = cardioTimeElapsed % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("CARDIO")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.armyGreen)
                

            Text(timeString)
                .font(.system(size: 60, weight: .thin, design: .monospaced))
                .foregroundColor(.armyGreen)
            
            Image("Elliptical")
                .resizable()
                .scaledToFill()
                .frame(width: 300, height: 300)
                .cornerRadius(7) // Inner corner radius
                .padding(5) // Width of the border
                .background(Color.armyGreen) // Color of the border
                .cornerRadius(10)
            
            Button(action: {
                showEndWorkoutConfirmation = true
            }) {
                Text("End Workout")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            Spacer()
        }
        .padding()
        .navigationTitle("Cardio Session")
        .navigationBarBackButtonHidden(true)
        .alert("End Workout?", isPresented: $showEndWorkoutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("End Workout", role: .destructive) {
                endWorkout()
            }
        } message: {
            Text("Are you sure you want to end the workout?")
        }
    }
    
    private func endWorkout() {
        // Call the completion handler with cardio time only
        if let onComplete = onComplete {
            onComplete(cardioTimeElapsed)
        } else {
            // Fallback for preview/testing
            dismiss()
        }
    }
}

#Preview {
    CardioWorkoutView(group: "Falcon", lastWorkoutGroup: .constant(nil), totalTimeElapsed: .constant(600), cardioStartTime: 300, onComplete: nil)
        .modelContainer(for: [Exercise.self, WorkoutHistory.self], inMemory: true)
}
