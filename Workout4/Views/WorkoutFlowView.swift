//
//  WorkoutFlowView.swift
//  Workout4
//
//  Created by Warren Hansen on 4/9/25.
//

import SwiftUI
import SwiftData

struct WorkoutFlowView: View {
    let targetGroup: String
    @Binding var lastWorkoutGroup: String?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var currentPhase: WorkoutPhase = .stretch
    @State private var timeElapsed: Int = 0
    @State private var timer: Timer?
    @State private var stretchCompleted = false
    @State private var showCardioOption = false
    
    enum WorkoutPhase {
        case stretch
        case mainWorkout
        case cardio
    }
    
    var body: some View {
        Group {
            if currentPhase == .stretch {
                StretchWorkoutView(
                    timeElapsed: $timeElapsed,
                    onComplete: {
                        stretchCompleted = true
                        withAnimation {
                            currentPhase = .mainWorkout
                        }
                    }
                )
            } else if currentPhase == .mainWorkout {
                MainWorkoutView(
                    group: targetGroup,
                    lastWorkoutGroup: $lastWorkoutGroup,
                    initialTimeElapsed: timeElapsed,
                    stretchCompleted: stretchCompleted,
                    onComplete: {
                        // Check if this is a strength training workout that can have cardio
                        if isStrengthTrainingGroup(targetGroup) {
                            showCardioOption = true
                        } else {
                            dismiss()
                        }
                    }
                )
            } else {
                CardioWorkoutView(
                    group: targetGroup,
                    lastWorkoutGroup: $lastWorkoutGroup,
                    initialTimeElapsed: timeElapsed
                )
            }
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
        .alert("Add Cardio?", isPresented: $showCardioOption) {
            Button("Skip", role: .cancel) {
                dismiss()
            }
            Button("Add Cardio") {
                withAnimation {
                    currentPhase = .cardio
                }
            }
        } message: {
            Text("Would you like to extend your workout with cardio?")
        }
    }
    
    private func isStrengthTrainingGroup(_ group: String) -> Bool {
        let strengthGroups = ["falcon", "deep horizon", "challenger", "trident"]
        return strengthGroups.contains(group.lowercased())
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
}

struct StretchWorkoutView: View {
    @Query private var allExercises: [Exercise]
    @Environment(\.modelContext) private var modelContext
    @Binding var timeElapsed: Int
    let onComplete: () -> Void
    
    @State private var completedSets: Set<String> = []
    
    var stretchExercises: [Exercise] {
        allExercises.filter { $0.group.lowercased() == "stretch" }
    }
    
    var groupedExercises: [String: [Exercise]] {
        Dictionary(grouping: stretchExercises, by: { $0.name })
    }
    
    var allSetsCompleted: Bool {
        var totalSetsNeeded = 0
        for (_, exerciseGroup) in groupedExercises {
            if let first = exerciseGroup.first {
                totalSetsNeeded += first.numSets
            }
        }
        return completedSets.count == totalSetsNeeded && totalSetsNeeded > 0
    }
    
    var timeString: String {
        let minutes = timeElapsed / 60
        let seconds = timeElapsed % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var body: some View {
        List {
            Section(header: Text("Complete stretches before workout").font(.headline)) {
                ForEach(groupedExercises.keys.sorted(), id: \.self) { exerciseName in
                    if let exerciseGroup = groupedExercises[exerciseName] {
                        ForEach(0..<exerciseGroup[0].numSets, id: \.self) { set in
                            let setId = "\(exerciseName)-\(set)"
                            HStack {
                                Text(exerciseName)
                                    .font(.body)
                                
                                Spacer()
                                
                                Text("\(exerciseGroup[0].numReps) reps")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Button(action: {
                                    if completedSets.contains(setId) {
                                        completedSets.remove(setId)
                                    } else {
                                        completedSets.insert(setId)
                                    }
                                    
                                    if allSetsCompleted {
                                        onComplete()
                                    }
                                }) {
                                    Image(systemName: completedSets.contains(setId) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(completedSets.contains(setId) ? .green : .gray)
                                        .font(.title2)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
        }
        .navigationTitle("Stretch First")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Text(timeString)
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Skip") {
                    onComplete()
                }
            }
        }
    }
}

struct MainWorkoutView: View {
    let group: String
    @Binding var lastWorkoutGroup: String?
    let initialTimeElapsed: Int
    let stretchCompleted: Bool
    let onComplete: (() -> Void)?
    
    @Query private var allExercises: [Exercise]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var timer: Timer?
    @State private var timeElapsed: Int = 0
    @State private var completedSets: Set<String> = []
    
    var exercises: [Exercise] {
        allExercises.filter { $0.group == group }
    }
    
    var groupedExercises: [String: [Exercise]] {
        Dictionary(grouping: exercises, by: { $0.name })
    }
    
    var timeString: String {
        let totalTime = initialTimeElapsed + timeElapsed
        let minutes = totalTime / 60
        let seconds = totalTime % 60
        return String(format: "%02d:%02d", minutes, seconds)
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
                                        .foregroundColor(exerciseGroup[0].weight > 0 ? .blue : .gray)
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
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            Spacer()
                            
                            // Sets controls
                            HStack(spacing: 8) {
                                Button(action: {
                                    if exerciseGroup[0].numSets > 1 {
                                        exerciseGroup[0].numSets -= 1
                                        saveChanges()
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
                                        .foregroundColor(exerciseGroup[0].numSets > 1 ? .blue : .gray)
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
                                        .foregroundColor(exerciseGroup[0].numSets < 4 ? .blue : .gray)
                                }
                                .disabled(exerciseGroup[0].numSets >= 4)
                            }
                        }
                    }) {
                        ForEach(0..<exerciseGroup[0].numSets, id: \.self) { set in
                            let setId = "\(exerciseName)-\(set)"
                            HStack {
                                Text("Set \(set + 1)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .frame(width: 50, alignment: .leading)
                                
                                Spacer()
                                
                                Text("\(exerciseGroup[0].numReps) reps")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Button(action: {
                                    if completedSets.contains(setId) {
                                        completedSets.remove(setId)
                                    } else {
                                        completedSets.insert(setId)
                                    }
                                    checkCompletion()
                                }) {
                                    Image(systemName: completedSets.contains(setId) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(completedSets.contains(setId) ? .green : .gray)
                                        .font(.title2)
                                }
                            }
                            .padding(.vertical, 8)
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
            resetCompletedStatus()
            completedSets.removeAll()
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
        var totalSetsNeeded = 0
        for (_, exerciseGroup) in groupedExercises {
            if let first = exerciseGroup.first {
                totalSetsNeeded += first.numSets
            }
        }
        
        let allCompleted = completedSets.count == totalSetsNeeded
        if allCompleted {
            stopTimer()
            
            lastWorkoutGroup = group
            UserDefaults.standard.set(group, forKey: "lastWorkoutGroup")
            
            let totalTime = initialTimeElapsed + timeElapsed
            let history = WorkoutHistory(
                id: UUID().uuidString,
                group: group,
                date: Date(),
                timeElapsed: totalTime
            )
            modelContext.insert(history)
            
            // Save to HealthKit
            HealthKitManager.shared.saveWorkout(group: group, timeElapsed: totalTime) { success in
                if success {
                    print("Workout saved to HealthKit")
                } else {
                    print("Failed to save workout to HealthKit")
                }
            }
            
            resetCompletedStatus()
            
            // Call completion handler if provided, otherwise dismiss
            if let onComplete = onComplete {
                onComplete()
            } else {
                dismiss()
            }
        }
    }
    
    private func resetCompletedStatus() {
        exercises.forEach { exercise in
            exercise.completed = false
        }
        saveChanges()
    }
    
    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            print("Error saving changes: \(error)")
        }
    }
}