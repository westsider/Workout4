//
//  TrainingPlanView.swift
//  Workout4
//
//  Created by Warren Hansen on 4/9/25.
//

import SwiftData
import SwiftUI

struct TrainingPlanView: View {
    @Query private var exercises: [Exercise]
    @Query(sort: \WorkoutHistory.date, order: .reverse) private var workoutHistory: [WorkoutHistory]
    @Binding var lastWorkoutGroup: String?
    
    var groupedExercises: [String: [Exercise]] {
        Dictionary(grouping: exercises, by: { $0.group })
    }
    
    // Custom sorted groups with "Stretch" and "Calisthenics" at the end
    var sortedGroups: [String] {
        let groups = groupedExercises.keys
        let priorityGroups = groups.filter { $0.lowercased() != "stretch" && $0.lowercased() != "calisthenics" }.sorted()
        let stretchGroup = groups.contains { $0.lowercased() == "stretch" } ? ["stretch"] : []
        let calisthenicsGroup = groups.contains { $0.lowercased() == "calisthenics" } ? ["Calisthenics"] : []
        return priorityGroups + stretchGroup + calisthenicsGroup
    }
    
    var body: some View {
        NavigationView {
            List {
                if exercises.isEmpty {
                    Text("No workouts available!")
                        .font(.title)
                        .foregroundColor(.gray)
                } else {
                    ForEach(sortedGroups, id: \.self) { group in
                        NavigationLink(destination: group.lowercased() == "stretch" 
                            ? AnyView(WorkoutDetailView(group: group, lastWorkoutGroup: $lastWorkoutGroup))
                            : AnyView(WorkoutFlowView(targetGroup: group, lastWorkoutGroup: $lastWorkoutGroup))) {
                            HStack {
                                // Placeholder for the image
                                Image(group)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .cornerRadius(7) // Inner corner radius
                                        .padding(5) // Width of the border
                                        .background(Color.primary) // Color of the border
                                        .cornerRadius(10)
                                VStack(alignment: .leading) {
                                    Text(group)
                                        .font(.headline)
                                    Text(subtitle(for: group))
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    if let lastWorkout = lastWorkoutDate(for: group) {
                                        Text(lastWorkout)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    } else {
                                        Text("Not started")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    // Progress bar
                                    ProgressView(value: lastWorkoutGroup == group ? 1.0 : 0.25)
                                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                        .frame(height: 5)
                                }
                                
                                Spacer()
                                
                                if let duration = lastWorkoutDuration(for: group) {
                                    Text(duration)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                } else {
                                    Text("00:00")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Basic Training")
            .onAppear {
                // Debug: Print the number of exercises fetched
                print("Fetched \(exercises.count) exercises")
                print("Groups: \(sortedGroups)")
            }
        }
    }
    
    private func subtitle(for group: String) -> String {
        switch group {
        case "Falcon":
            return "Don't Get Snatched"
        case "Deep Horizon":
            return "We Take You To Crush Depth"
        case "Challenger":
            return "Failure Is Not An Option"
        case "Trident":
            return "Only Easy Day Was Yesterday"
        case "stretch":
            return "Just Let It Go"
        case "Calisthenics":
            return "" // No subtitle in the screenshot
        default:
            return ""
        }
    }
    
    private func lastWorkoutDate(for group: String) -> String? {
        if let workout = workoutHistory.first(where: { $0.group == group }) {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy h:mma"
            return formatter.string(from: workout.date)
        }
        return nil
    }
    
    private func lastWorkoutDuration(for group: String) -> String? {
        if let workout = workoutHistory.first(where: { $0.group == group }) {
            let minutes = workout.timeElapsed / 60
            let seconds = workout.timeElapsed % 60
            return String(format: "%02d:%02d", minutes, seconds)
        }
        return nil
    }
}
