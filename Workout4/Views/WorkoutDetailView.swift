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
    @State private var completedSets: Set<String> = []
    
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
                            let setId = "\(exerciseName)-\(set)"
                            HStack {
                                Text("\(exerciseGroup[0].weight) lbs")
                                Spacer()
                                Text("\(exerciseGroup[0].numReps) Reps")
                                Spacer()
                                Button(action: {
                                    // Toggle set completion
                                    if completedSets.contains(setId) {
                                        completedSets.remove(setId)
                                    } else {
                                        completedSets.insert(setId)
                                    }
                                    checkCompletion()
                                }) {
                                    Image(systemName: completedSets.contains(setId) ? "star.fill" : "star")
                                        .foregroundColor(completedSets.contains(setId) ? .blue : .gray)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(group)
        .navigationBarItems(trailing: Text(timeString)
            .font(.headline)
            .foregroundColor(.blue))
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
            // Reset completed status when leaving the view
            resetCompletedStatus()
            completedSets.removeAll()
        }
    }
    
    private var timeString: String {
        let minutes = timeElapsed / 60
        let seconds = timeElapsed % 60
        return String(format: "%02d:%02d", minutes, seconds)
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
        // Calculate total sets needed
        var totalSetsNeeded = 0
        for (_, exerciseGroup) in groupedExercises {
            if let first = exerciseGroup.first {
                totalSetsNeeded += first.numSets
            }
        }
        
        // Check if all sets are completed
        allCompleted = completedSets.count == totalSetsNeeded
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
                    timeElapsed: timeElapsed + 240 // 4 minute stretch
                )
                modelContext.insert(history)
            }
            
            // Reset completed status before dismissing
            resetCompletedStatus()
            
            // Navigate back
            dismiss()
        }
    }
    
    private func resetCompletedStatus() {
        // Reset the completed property for all exercises in this group
        exercises.forEach { exercise in
            exercise.completed = false
        }
        // Save the changes to SwiftData
        do {
            try modelContext.save()
        } catch {
            print("Error saving context after resetting completed status: \(error)")
        }
    }
}
