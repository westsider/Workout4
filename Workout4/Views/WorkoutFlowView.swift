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
    @State private var strengthWorkoutTime: Int = 0
    
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
                    timeElapsed: $timeElapsed,  // Pass as binding for live updates
                    stretchCompleted: stretchCompleted,
                    shouldSaveWorkout: !isStrengthTrainingGroup(targetGroup),  // Only save if no cardio option
                    onComplete: {
                        // Save the time elapsed at the end of strength workout
                        strengthWorkoutTime = timeElapsed
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
                    totalTimeElapsed: $timeElapsed,  // Pass binding to the master timer
                    cardioStartTime: strengthWorkoutTime,  // When cardio started
                    onComplete: { cardioTime in
                        // Save with total time from master timer
                        saveWorkoutAndDismiss(group: targetGroup, timeElapsed: timeElapsed, withCardio: true, cardioTime: cardioTime)
                    }
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
                // Save workout without cardio
                saveWorkoutAndDismiss(group: targetGroup, timeElapsed: timeElapsed, withCardio: false)
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
        print("WorkoutFlowView - Starting timer")
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            timeElapsed += 1
            if timeElapsed % 30 == 0 {  // Log every 30 seconds
                print("WorkoutFlowView - Timer: \(timeElapsed) seconds (\(timeElapsed/60) min \(timeElapsed%60) sec)")
            }
        }
    }
    
    private func stopTimer() {
        print("WorkoutFlowView - Stopping timer at \(timeElapsed) seconds")
        timer?.invalidate()
        timer = nil
    }
    
    private func saveWorkoutAndDismiss(group: String, timeElapsed: Int, withCardio: Bool, cardioTime: Int = 0) {
        lastWorkoutGroup = group
        UserDefaults.standard.set(group, forKey: "lastWorkoutGroup")
        
        let workoutName = withCardio ? "\(group) + Cardio" : group
        let calories = HealthKitManager.shared.calculateCalories(for: workoutName, duration: timeElapsed)
        let history = WorkoutHistory(
            id: UUID().uuidString,
            group: workoutName,
            date: Date(),
            timeElapsed: timeElapsed,
            caloriesBurned: calories
        )
        if withCardio {
            print("WorkoutFlowView - Saving workout: \(workoutName)")
            print("  Stretch + Strength time: \(strengthWorkoutTime) seconds (\(strengthWorkoutTime/60) minutes)")
            print("  Cardio time: \(cardioTime) seconds (\(cardioTime/60) minutes)")
            print("  Total time: \(timeElapsed) seconds (\(timeElapsed/60) minutes)")
        } else {
            print("WorkoutFlowView - Saving workout: \(workoutName), total time: \(timeElapsed) seconds (\(timeElapsed/60) minutes)")
        }
        modelContext.insert(history)
        
        // Save to HealthKit
        print("WorkoutFlowView - Saving to HealthKit: \(workoutName), time: \(timeElapsed) seconds")
        HealthKitManager.shared.saveWorkout(group: workoutName, timeElapsed: timeElapsed) { success in
            if success {
                print("Workout saved to HealthKit successfully")
            } else {
                print("Failed to save workout to HealthKit")
            }
        }
        
        dismiss()
    }
}

struct StretchWorkoutView: View {
    @Query private var allExercises: [Exercise]
    @Environment(\.modelContext) private var modelContext
    @Binding var timeElapsed: Int
    let onComplete: () -> Void
    
    @State private var completedExercises: Set<String> = []
    
    var stretchExercises: [Exercise] {
        allExercises.filter { $0.group.lowercased() == "stretch" }
    }
    
    var groupedExercises: [String: [Exercise]] {
        Dictionary(grouping: stretchExercises, by: { $0.name })
    }
    
    var sortedExerciseNames: [String] {
        groupedExercises.keys.sorted()
    }
    
    var allExercisesCompleted: Bool {
        completedExercises.count == groupedExercises.count && !groupedExercises.isEmpty
    }
    
    var timeString: String {
        let minutes = timeElapsed / 60
        let seconds = timeElapsed % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var body: some View {
        VStack(spacing: 0) {
                // Header section
//                VStack(spacing: 8) {
//                    Text("COMPLETE STRETCHES")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                        .fontWeight(.medium)
//                    Text("BEFORE WORKOUT")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                        .fontWeight(.medium)
//                }
//                .padding(.top, 16)
//                .padding(.bottom, 24)
                
                // Exercise list
                List {
                    ForEach(sortedExerciseNames, id: \.self) { exerciseName in
                        if let exerciseGroup = groupedExercises[exerciseName] {
                            let isCompleted = completedExercises.contains(exerciseName)
                            
                            HStack(spacing: 16) {
                                // Exercise icon
                                Image("yogapose2")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(isCompleted ? .white : .primary)
                                    .padding(5)
                                    .frame(width: 50, height: 50)
                                    .background(isCompleted ? Color.armyGreenLight : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                // Exercise details
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(exerciseName)
                                        .font(.headline)
                                        .foregroundColor(isCompleted ? .white : .primary)
                                    
                                    Text("\(exerciseGroup[0].numReps) reps")
                                        .font(.subheadline)
                                        .foregroundColor(isCompleted ? .white.opacity(0.8) : .secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(isCompleted ? Color.armyGreenLight : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if isCompleted {
                                        completedExercises.remove(exerciseName)
                                    } else {
                                        completedExercises.insert(exerciseName)
                                    }
                                    
                                    if allExercisesCompleted {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            onComplete()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Stretch First")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.armyGreen, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .tint(.white)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Text(timeString)
                        .font(.headline)
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") {
                        onComplete()
                    }
                    .foregroundColor(.white)
                }
            }
    }
}

struct MainWorkoutView: View {
    let group: String
    @Binding var lastWorkoutGroup: String?
    @Binding var timeElapsed: Int  // Changed to binding for live updates
    let stretchCompleted: Bool
    var shouldSaveWorkout: Bool = true  // Flag to control if this view should save
    let onComplete: (() -> Void)?
    
    @Query private var allExercises: [Exercise]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var completedSets: Set<String> = []
    
    var exercises: [Exercise] {
        allExercises.filter { $0.group == group }
    }
    
    var groupedExercises: [String: [Exercise]] {
        Dictionary(grouping: exercises, by: { $0.name })
    }
    
    var timeString: String {
        let minutes = timeElapsed / 60
        let seconds = timeElapsed % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var body: some View {
        List {
            ForEach(groupedExercises.keys.sorted(), id: \.self) { exerciseName in
                if let exerciseGroup = groupedExercises[exerciseName] {
                    Section(header: VStack(alignment: .leading, spacing: 8) {
                        Text(exerciseName)
                            .font(.headline)
                            .foregroundColor(.armyGreen)
                        
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
        .navigationTitle(group.uppercased())
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.armyGreen, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .tint(.white)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Text(timeString)
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .onDisappear {
            resetCompletedStatus()
            completedSets.removeAll()
        }
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
            // Only save if we should (i.e., no cardio option will be presented)
            if shouldSaveWorkout {
                lastWorkoutGroup = group
                UserDefaults.standard.set(group, forKey: "lastWorkoutGroup")
                
                let calories = HealthKitManager.shared.calculateCalories(for: group, duration: timeElapsed)
                let history = WorkoutHistory(
                    id: UUID().uuidString,
                    group: group,
                    date: Date(),
                    timeElapsed: timeElapsed,
                    caloriesBurned: calories
                )
                print("MainWorkoutView - Saving workout: \(group), time: \(timeElapsed) seconds (\(timeElapsed/60) minutes)")
                modelContext.insert(history)
                
                // Save to HealthKit
                print("MainWorkoutView - Saving to HealthKit: \(group), time: \(timeElapsed) seconds")
                HealthKitManager.shared.saveWorkout(group: group, timeElapsed: timeElapsed) { success in
                    if success {
                        print("Workout saved to HealthKit successfully")
                    } else {
                        print("Failed to save workout to HealthKit")
                    }
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

#Preview {
    let container = try! ModelContainer(for: Exercise.self, WorkoutHistory.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    
    // Add sample Challenger exercises and stretch exercises
    let sampleExercises = [
        // Challenger exercises
        Exercise(id: "1", group: "Challenger", name: "Burpees", numReps: 10, numSets: 3, weight: 0, completed: false, date: Date(), timeElapsed: 0),
        Exercise(id: "2", group: "Challenger", name: "Mountain Climbers", numReps: 20, numSets: 3, weight: 0, completed: false, date: Date(), timeElapsed: 0),
        Exercise(id: "3", group: "Challenger", name: "Squat Jumps", numReps: 15, numSets: 3, weight: 0, completed: false, date: Date(), timeElapsed: 0),
        Exercise(id: "4", group: "Challenger", name: "Push-up to T", numReps: 8, numSets: 3, weight: 0, completed: false, date: Date(), timeElapsed: 0),
        
        // Stretch exercises (needed for the stretch phase)
        Exercise(id: "5", group: "Stretch", name: "Hamstring Stretch", numReps: 30, numSets: 1, weight: 0, completed: false, date: Date(), timeElapsed: 0),
        Exercise(id: "6", group: "Stretch", name: "Quad Stretch", numReps: 20, numSets: 1, weight: 0, completed: false, date: Date(), timeElapsed: 0)
    ]
    
    for exercise in sampleExercises {
        container.mainContext.insert(exercise)
    }
    
    return WorkoutFlowView(targetGroup: "Challenger", lastWorkoutGroup: .constant("Falcon"))
        .modelContainer(container)
}
