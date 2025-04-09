//
//  WorkoutDetailView.swift
//  Workout4
//
//  Created by Warren Hansen on 4/9/25.
//

import SwiftData
import SwiftUI

struct WorkoutDetailView: View {
    let group: String
    @Query private var allExercises: [Exercise] // Fetch all exercises
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Binding var lastWorkoutGroup: String?
    
    @State private var timer: Timer?
    @State private var timeElapsed: Int = 0
    @State private var allCompleted: Bool = false
    
    // Filter exercises for the current group
    var exercises: [Exercise] {
        allExercises.filter { $0.group == group }
    }
    
    // Group exercises by name to handle multiple sets
    var groupedExercises: [String: [Exercise]] {
        Dictionary(grouping: exercises, by: { $0.name })
    }
    
    var body: some View {
        List {
            ForEach(groupedExercises.keys.sorted(), id: \.self) { exerciseName in
                if let exerciseGroup = groupedExercises[exerciseName] {
                    Section(header: Text(exerciseName).font(.headline)) {
                        ForEach(0..<exerciseGroup[0].numSets, id: \.self) { set in
                            HStack {
                                Text("\(exerciseGroup[0].weight) lbs")
                                Spacer()
                                Text("\(exerciseGroup[0].numReps) Reps")
                                Spacer()
                                Button(action: {
                                    // Mark the set as completed
                                    exerciseGroup[0].completed = true
                                    checkCompletion()
                                }) {
                                    Image(systemName: exerciseGroup[0].completed ? "star.fill" : "star")
                                        .foregroundColor(exerciseGroup[0].completed ? .blue : .gray)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(group)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
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
    
    private func checkCompletion() {
        // Check if all exercises in this group are completed
        allCompleted = exercises.allSatisfy { $0.completed }
        if allCompleted {
            stopTimer()
            
            // Update the last workout group
            lastWorkoutGroup = group
            UserDefaults.standard.set(group, forKey: "lastWorkoutGroup")
            
            // Record in history (except for "stretch")
            if group.lowercased() != "stretch" {
                let history = WorkoutHistory(
                    id: UUID().uuidString,
                    group: group,
                    date: Date(),
                    timeElapsed: timeElapsed
                )
                modelContext.insert(history)
            }
            
            // Navigate back
            dismiss()
        }
    }
}
