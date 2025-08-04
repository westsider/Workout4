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
    let initialTimeElapsed: Int
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var timer: Timer?
    @State private var timeElapsed: Int = 0
    @State private var showEndWorkoutConfirmation = false
    
    var totalTimeElapsed: Int {
        initialTimeElapsed + timeElapsed
    }
    
    var timeString: String {
        let minutes = totalTimeElapsed / 60
        let seconds = totalTimeElapsed % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var body: some View {
        VStack(spacing: 40) {
            Text("Cardio")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(timeString)
                .font(.system(size: 60, weight: .thin, design: .monospaced))
                .foregroundColor(.blue)
            
            Text("Keep going! 💪")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Spacer()
            
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
        }
        .padding()
        .navigationTitle("Cardio Session")
        .navigationBarBackButtonHidden(true)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
        .alert("End Workout?", isPresented: $showEndWorkoutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("End Workout", role: .destructive) {
                endWorkout()
            }
        } message: {
            Text("Are you sure you want to end the workout?")
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            timeElapsed += 1
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func endWorkout() {
        stopTimer()
        
        // Update last workout group
        lastWorkoutGroup = group
        UserDefaults.standard.set(group, forKey: "lastWorkoutGroup")
        
        // Save to history
        let history = WorkoutHistory(
            id: UUID().uuidString,
            group: "\(group) + Cardio",
            date: Date(),
            timeElapsed: totalTimeElapsed
        )
        modelContext.insert(history)
        
        // Save to HealthKit
        HealthKitManager.shared.saveWorkout(group: "\(group) + Cardio", timeElapsed: totalTimeElapsed) { success in
            if success {
                print("Cardio workout saved to HealthKit")
            } else {
                print("Failed to save cardio workout to HealthKit")
            }
        }
        
        dismiss()
    }
}

#Preview {
    CardioWorkoutView(group: "Falcon", lastWorkoutGroup: .constant(nil), initialTimeElapsed: 600)
        .modelContainer(for: [Exercise.self, WorkoutHistory.self], inMemory: true)
}