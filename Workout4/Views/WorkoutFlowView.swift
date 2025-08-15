//
//  WorkoutFlowView.swift
//  Workout4
//
//  Created by Warren Hansen on 4/9/25.
//

import SwiftUI
import SwiftData
import AVKit

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
    @State private var startTime: Date = Date()
    
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
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            updateTimeFromBackground()
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
        startTime = Date()
        print("WorkoutFlowView - Starting timer at \(startTime)")
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            updateTimeElapsed()
            if timeElapsed % 30 == 0 {  // Log every 30 seconds
                print("WorkoutFlowView - Timer: \(timeElapsed) seconds (\(timeElapsed/60) min \(timeElapsed%60) sec)")
            }
        }
    }
    
    private func updateTimeElapsed() {
        timeElapsed = Int(Date().timeIntervalSince(startTime))
    }
    
    private func updateTimeFromBackground() {
        print("WorkoutFlowView - Updating time from background")
        updateTimeElapsed()
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
    @Environment(\.dismiss) private var dismiss
    @Binding var timeElapsed: Int
    let onComplete: () -> Void
    
    @State private var completedExercises: Set<String> = []
    @State private var showQuitConfirmation = false
    @State private var showingVideoPlayer = false
    @State private var selectedVideoURL: URL?
    
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
    
    private func imageNameForExercise(_ exerciseName: String) -> String {
        switch exerciseName.lowercased() {
        case "band pulls":
            return "band-pulls"
        case "glute back bridges":
            return "glute-back-bridge"
        case "hip flexor stretch":
            return "hip-flexor-stretch"
        case "yoga push up":
            return "yoga-push-up"
        case "fire hydrant":
            return "fire-hydrant"
        default:
            return "yogapose2"  // Fallback to generic yoga pose
        }
    }
    
    private func videoFileNameForExercise(_ exerciseName: String) -> String? {
        switch exerciseName.lowercased() {
        case "band pulls":
            return "band_pulls_final"
        case "glute back bridges":
            return "glute-bridges-final"
        case "hip flexor stretch":
            return "hip-flexor-final"
        case "yoga push up":
            return "Yoga-push-up-final"
        case "fire hydrant":
            return "fire-hydrant-final"
        default:
            return nil
        }
    }
    
    private func findVideoURL(for exerciseName: String) -> URL? {
        guard let videoName = videoFileNameForExercise(exerciseName) else { return nil }
        
        // First try to find in the bundle
        if let url = Bundle.main.url(forResource: videoName, withExtension: "mov") {
            return url
        }
        if let url = Bundle.main.url(forResource: videoName, withExtension: "mp4") {
            return url
        }
        
        // If not in bundle, try to find in Videos subfolder
        if let url = Bundle.main.url(forResource: videoName, withExtension: "mov", subdirectory: "Videos") {
            return url
        }
        if let url = Bundle.main.url(forResource: videoName, withExtension: "mp4", subdirectory: "Videos") {
            return url
        }
        
        // If still not found, try document directory as fallback
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let videosPath = documentsPath.appendingPathComponent("Videos")
        
        let movURL = videosPath.appendingPathComponent("\(videoName).mov")
        if FileManager.default.fileExists(atPath: movURL.path) {
            return movURL
        }
        
        let mp4URL = videosPath.appendingPathComponent("\(videoName).mp4")
        if FileManager.default.fileExists(atPath: mp4URL.path) {
            return mp4URL
        }
        
        return nil
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
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(sortedExerciseNames, id: \.self) { exerciseName in
                            if let exerciseGroup = groupedExercises[exerciseName] {
                                let isCompleted = completedExercises.contains(exerciseName)
                                
                                HStack(spacing: 12) {
                                    // Checkbox for completion
                                    Button(action: {
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
                                    }) {
                                        Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 28))
                                            .foregroundColor(isCompleted ? .armyGreen : .gray)
                                    }
                                    
                                    // Exercise icon
                                    Image(imageNameForExercise(exerciseName))
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(.primary)
                                    
                                    // Exercise details
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(exerciseName)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        Text("\(exerciseGroup[0].numReps) reps")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    // Video tutorial button
                                    if videoFileNameForExercise(exerciseName) != nil {
                                        Button(action: {
                                            print("Video button tapped for: \(exerciseName)")
                                            if let url = findVideoURL(for: exerciseName) {
                                                print("Found video at: \(url)")
                                                selectedVideoURL = url
                                                showingVideoPlayer = true
                                            } else {
                                                print("No video found for: \(exerciseName)")
                                                // Show an alert or fallback
                                            }
                                        }) {
                                            Image(systemName: "play.circle.fill")
                                                .font(.system(size: 32))
                                                .foregroundColor(.armyGreen)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .navigationTitle("Stretch First")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.armyGreen, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .tint(.white)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showQuitConfirmation = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.white)
                    }
                }
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
            .alert("Quit Workout?", isPresented: $showQuitConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Quit", role: .destructive) {
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to quit this workout? Your progress will not be saved.")
            }
            .fullScreenCover(isPresented: $showingVideoPlayer) {
                if let videoURL = selectedVideoURL {
                    FullScreenVideoPlayer(url: videoURL, isPresented: $showingVideoPlayer)
                } else {
                    VStack {
                        Text("Video not available")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Button("Close") {
                            showingVideoPlayer = false
                        }
                        .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                }
            }
    }
}

struct FullScreenVideoPlayer: View {
    let url: URL
    @Binding var isPresented: Bool
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            if let player = player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            }
            
            // Close button overlay
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        player?.pause()
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .onAppear {
            print("FullScreenVideoPlayer appeared with URL: \(url)")
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
    
    private func setupPlayer() {
        player = AVPlayer(url: url)
        
        // Enable auto play
        player?.play()
        
        // Optional: Set up looping (uncomment if you want the video to loop)
        // NotificationCenter.default.addObserver(
        //     forName: .AVPlayerItemDidPlayToEndTime,
        //     object: player?.currentItem,
        //     queue: .main
        // ) { _ in
        //     player?.seek(to: CMTime.zero)
        //     player?.play()
        // }
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
    @State private var showQuitConfirmation = false
    @State private var showingVideoPlayer = false
    @State private var selectedVideoURL: URL?
    @State private var selectedExerciseName: String = ""
    
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
                        HStack {
                            Text(exerciseName)
                                .font(.headline)
                                .foregroundColor(.armyGreen)
                            
                            Spacer()
                            
                            // Video tutorial button
                            if VideoManager.shared.getVideoFileName(for: exerciseName, in: group) != nil {
                                Button(action: {
                                    if let url = VideoManager.shared.findVideoURL(for: exerciseName, in: group) {
                                        selectedVideoURL = url
                                        selectedExerciseName = exerciseName
                                        showingVideoPlayer = true
                                    }
                                }) {
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.armyGreen)
                                }
                            }
                        }
                        
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
        .navigationBarBackButtonHidden(true)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.armyGreen, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .tint(.white)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    showQuitConfirmation = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.white)
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Text(timeString)
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .alert("Quit Workout?", isPresented: $showQuitConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Quit", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("Are you sure you want to quit this workout? Your progress will not be saved.")
        }
        .fullScreenCover(isPresented: $showingVideoPlayer) {
            if let videoURL = selectedVideoURL {
                ExerciseVideoPlayer(url: videoURL, exerciseName: selectedExerciseName, isPresented: $showingVideoPlayer)
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
    
    // Add sample Challenger exercises and ALL stretch exercises for preview
    let sampleExercises = [
        // Challenger exercises
        Exercise(id: "1", group: "Challenger", name: "Burpees", numReps: 10, numSets: 3, weight: 0, completed: false, date: Date(), timeElapsed: 0),
        Exercise(id: "2", group: "Challenger", name: "Mountain Climbers", numReps: 20, numSets: 3, weight: 0, completed: false, date: Date(), timeElapsed: 0),
        Exercise(id: "3", group: "Challenger", name: "Squat Jumps", numReps: 15, numSets: 3, weight: 0, completed: false, date: Date(), timeElapsed: 0),
        Exercise(id: "4", group: "Challenger", name: "Push-up to T", numReps: 8, numSets: 3, weight: 0, completed: false, date: Date(), timeElapsed: 0),
        
        // All Stretch exercises with video tutorials
        Exercise(id: "5", group: "Stretch", name: "Band Pulls", numReps: 15, numSets: 1, weight: 0, completed: false, date: Date(), timeElapsed: 0),
        Exercise(id: "6", group: "Stretch", name: "Glute Back Bridges", numReps: 20, numSets: 1, weight: 0, completed: false, date: Date(), timeElapsed: 0),
        Exercise(id: "7", group: "Stretch", name: "Hip Flexor Stretch", numReps: 30, numSets: 1, weight: 0, completed: false, date: Date(), timeElapsed: 0),
        Exercise(id: "8", group: "Stretch", name: "Yoga Push Up", numReps: 10, numSets: 1, weight: 0, completed: false, date: Date(), timeElapsed: 0),
        Exercise(id: "9", group: "Stretch", name: "Fire Hydrant", numReps: 15, numSets: 1, weight: 0, completed: false, date: Date(), timeElapsed: 0)
    ]
    
    for exercise in sampleExercises {
        container.mainContext.insert(exercise)
    }
    
    return WorkoutFlowView(targetGroup: "Challenger", lastWorkoutGroup: .constant("Falcon"))
        .modelContainer(container)
}

// Shared video player view for exercises
struct ExerciseVideoPlayer: View {
    let url: URL
    let exerciseName: String
    @Binding var isPresented: Bool
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            if let player = player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            }
            
            // Close button and title overlay
            VStack {
                HStack {
                    Text(exerciseName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        player?.pause()
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                }
                .padding()
                
                Spacer()
            }
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
    
    private func setupPlayer() {
        player = AVPlayer(url: url)
        player?.play()
    }
}


// Special workout flow for Elliptical - goes Stretch -> Cardio directly
struct EllipticalWorkoutFlow: View {
    let targetGroup: String = "Elliptical"
    @Binding var lastWorkoutGroup: String?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var currentPhase: EllipticalPhase = .stretch
    @State private var timeElapsed: Int = 0
    @State private var timer: Timer?
    @State private var stretchCompleted = false
    @State private var startTime: Date = Date()
    @State private var cardioStartTime: Int = 0
    
    enum EllipticalPhase {
        case stretch
        case cardio
    }
    
    var body: some View {
        Group {
            if currentPhase == .stretch {
                StretchWorkoutView(
                    timeElapsed: $timeElapsed,
                    onComplete: {
                        print("EllipticalWorkoutFlow - Stretch completed, transitioning to cardio. Time elapsed: \(timeElapsed)")
                        cardioStartTime = timeElapsed  // Capture when cardio starts
                        stretchCompleted = true
                        withAnimation {
                            currentPhase = .cardio
                        }
                        print("EllipticalWorkoutFlow - Phase changed to cardio, cardioStartTime: \(cardioStartTime)")
                    }
                )
            } else {
                CardioWorkoutView(
                    group: targetGroup,
                    lastWorkoutGroup: $lastWorkoutGroup,
                    totalTimeElapsed: $timeElapsed,
                    cardioStartTime: cardioStartTime, // Use the captured start time
                    onComplete: { cardioTime in
                        // Save elliptical workout with total time
                        print("EllipticalWorkoutFlow - Cardio completed with \(cardioTime) cardio seconds. Total time: \(timeElapsed)")
                        saveEllipticalWorkout(totalTime: timeElapsed)
                    }
                )
            }
        }
        .onAppear {
            print("EllipticalWorkoutFlow - onAppear called")
            startTimer()
        }
        .onDisappear {
            print("EllipticalWorkoutFlow - onDisappear called")
            stopTimer()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            updateTimeFromBackground()
        }
    }
    
    private func startTimer() {
        startTime = Date()
        print("EllipticalWorkoutFlow - Starting timer at \(startTime)")
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            updateTimeElapsed()
            if timeElapsed % 10 == 0 {  // Log every 10 seconds for better debugging
                print("EllipticalWorkoutFlow - Timer tick: \(timeElapsed) seconds (\(timeElapsed/60) min \(timeElapsed%60) sec) - Phase: \(currentPhase == .stretch ? "stretch" : "cardio")")
            }
        }
        print("EllipticalWorkoutFlow - Timer created successfully: \(timer != nil)")
    }
    
    private func updateTimeElapsed() {
        let newTime = Int(Date().timeIntervalSince(startTime))
        if newTime != timeElapsed {  // Only log when time actually changes
            timeElapsed = newTime
            if timeElapsed % 5 == 0 {  // Log every 5 seconds for debugging
                print("EllipticalWorkoutFlow - Time updated: \(timeElapsed) seconds")
            }
        }
    }
    
    private func updateTimeFromBackground() {
        print("EllipticalWorkoutFlow - Updating time from background")
        updateTimeElapsed()
    }
    
    private func stopTimer() {
        print("EllipticalWorkoutFlow - Stopping timer at \(timeElapsed) seconds")
        timer?.invalidate()
        timer = nil
    }
    
    private func saveEllipticalWorkout(totalTime: Int) {
        lastWorkoutGroup = targetGroup
        UserDefaults.standard.set(targetGroup, forKey: "lastWorkoutGroup")
        
        let calories = HealthKitManager.shared.calculateCalories(for: targetGroup, duration: totalTime)
        let history = WorkoutHistory(
            id: UUID().uuidString,
            group: targetGroup,
            date: Date(),
            timeElapsed: totalTime,
            caloriesBurned: calories
        )
        
        print("EllipticalWorkoutFlow - Saving workout: \(targetGroup)")
        print("  Total time: \(totalTime) seconds (\(totalTime/60) minutes)")
        print("  Calories burned: \(calories)")
        
        modelContext.insert(history)
        
        // Save to HealthKit
        print("EllipticalWorkoutFlow - Saving to HealthKit: \(targetGroup), time: \(totalTime) seconds")
        HealthKitManager.shared.saveWorkout(group: targetGroup, timeElapsed: totalTime) { success in
            if success {
                print("Elliptical workout saved to HealthKit successfully")
            } else {
                print("Failed to save elliptical workout to HealthKit")
            }
        }
        
        dismiss()
    }
}
