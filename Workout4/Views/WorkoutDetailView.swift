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
    @State private var startTime: Date = Date()
    
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
                    Section(header: VStack(alignment: .leading, spacing: 8) {
                        Text(exerciseName)
                            .font(.headline)
                        
                        HStack {
                            // Weight controls
                            HStack(spacing: 8) {
                                Button(action: {
                                    if exerciseGroup[0].weight > 0 {
                                        exerciseGroup[0].weight -= 5
                                        saveChanges()
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(exerciseGroup[0].weight > 0 ? .armyGreen : .gray)
                                }
                                .disabled(exerciseGroup[0].weight <= 0)
                                
                                Text("\(exerciseGroup[0].weight) lbs")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .frame(minWidth: 60)
                                
                                Button(action: {
                                    exerciseGroup[0].weight += 5
                                    saveChanges()
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.armyGreen)
                                }
                            }
                            
                            Spacer()
                            
                            // Sets controls
                            HStack(spacing: 8) {
                                Button(action: {
                                    if exerciseGroup[0].numSets > 1 {
                                        exerciseGroup[0].numSets -= 1
                                        saveChanges()
                                        // Remove completed sets that are beyond the new count
                                        completedSets = completedSets.filter { setId in
                                            let components = setId.split(separator: "-")
                                            if components[0] == exerciseName,
                                               let setIndex = Int(components[1]),
                                               setIndex >= exerciseGroup[0].numSets {
                                                return false
                                            }
                                            return true
                                        }
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(exerciseGroup[0].numSets > 1 ? .armyGreen : .gray)
                                }
                                .disabled(exerciseGroup[0].numSets <= 1)
                                
                                Text("\(exerciseGroup[0].numSets) sets")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .frame(minWidth: 50)
                                
                                Button(action: {
                                    if exerciseGroup[0].numSets < 4 {
                                        exerciseGroup[0].numSets += 1
                                        saveChanges()
                                    }
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(exerciseGroup[0].numSets < 4 ? .armyGreen : .gray)
                                }
                                .disabled(exerciseGroup[0].numSets >= 4)
                            }
                        }
                    }) {
                        ForEach(0..<exerciseGroup[0].numSets, id: \.self) { set in
                            let setId = "\(exerciseName)-\(set)"
                            let isCompleted = completedSets.contains(setId)
                            
                            HStack {
                                Text("Set \(set + 1)")
                                    .font(.subheadline)
                                    .foregroundColor(isCompleted ? .white : .secondary)
                                    .frame(width: 50, alignment: .leading)
                                
                                Spacer()
                                
                                // Reps display
                                Text("\(exerciseGroup[0].numReps) reps")
                                    .font(.body)
                                    .foregroundColor(isCompleted ? .white : .primary)
                                
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(isCompleted ? Color.armyGreenLight : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    // Toggle set completion
                                    if completedSets.contains(setId) {
                                        completedSets.remove(setId)
                                    } else {
                                        completedSets.insert(setId)
                                    }
                                    checkCompletion()
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(group)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Text(timeString)
                    .font(.headline)
                    .foregroundColor(.blue)
            }
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
            // Reset completed status when leaving the view
            resetCompletedStatus()
            completedSets.removeAll()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            updateTimeFromBackground()
        }
    }
    
    private var timeString: String {
        let minutes = timeElapsed / 60
        let seconds = timeElapsed % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func startTimer() {
        startTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            updateTimeElapsed()
        }
    }
    
    private func updateTimeElapsed() {
        timeElapsed = Int(Date().timeIntervalSince(startTime))
    }
    
    private func updateTimeFromBackground() {
        updateTimeElapsed()
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
            
            // Record in history
            let finalTime = group.lowercased() == "stretch" ? timeElapsed : timeElapsed + 240
            print("WorkoutDetailView - Saving workout: \(group), raw time: \(timeElapsed)s, final time: \(finalTime)s (\(finalTime/60)m)")
            let history = WorkoutHistory(
                id: UUID().uuidString,
                group: group,
                date: Date(),
                timeElapsed: finalTime
            )
            modelContext.insert(history)
            
            // Save to HealthKit
            print("WorkoutDetailView - Saving to HealthKit: \(group), time: \(finalTime)s")
            HealthKitManager.shared.saveWorkout(group: group, timeElapsed: finalTime) { success in
                if success {
                    print("Workout saved to HealthKit successfully")
                } else {
                    print("Failed to save workout to HealthKit")
                }
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
    
    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            print("Error saving changes: \(error)")
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: Exercise.self, WorkoutHistory.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    
    // Add sample Challenger exercises
    let sampleExercises = [
        Exercise(id: "1", group: "Challenger", name: "Burpees", numReps: 10, numSets: 3, weight: 0, completed: false, date: Date(), timeElapsed: 0),
        Exercise(id: "2", group: "Challenger", name: "Mountain Climbers", numReps: 20, numSets: 3, weight: 0, completed: false, date: Date(), timeElapsed: 0),
        Exercise(id: "3", group: "Challenger", name: "Squat Jumps", numReps: 15, numSets: 3, weight: 0, completed: false, date: Date(), timeElapsed: 0),
        Exercise(id: "4", group: "Challenger", name: "Push-up to T", numReps: 8, numSets: 3, weight: 0, completed: false, date: Date(), timeElapsed: 0),
        Exercise(id: "5", group: "Challenger", name: "Plank Jacks", numReps: 12, numSets: 2, weight: 0, completed: false, date: Date(), timeElapsed: 0)
    ]
    
    for exercise in sampleExercises {
        container.mainContext.insert(exercise)
    }
    
    return WorkoutDetailView(group: "Challenger", lastWorkoutGroup: .constant("Falcon"))
        .modelContainer(container)
}
