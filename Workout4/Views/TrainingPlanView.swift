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
                        NavigationLink(destination: WorkoutDetailView(group: group, lastWorkoutGroup: $lastWorkoutGroup)) {
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
                                    Text(formattedDate(for: group))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    // Progress bar
                                    ProgressView(value: lastWorkoutGroup == group ? 1.0 : 0.25)
                                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                        .frame(height: 5)
                                }
                                
                                Spacer()
                                
                                Text("00:00")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Training Plan")
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
    
    private func formattedDate(for group: String) -> String {
        if group.lowercased() == "stretch" {
            return "Apr 9, 2025 10:09AM"
        }
        return "Feb 1, 2023 10:31PM"
    }
}
