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
    
    var body: some View {
        NavigationView {
            List {
                if exercises.isEmpty {
                    Text("No workouts available!")
                        .font(.title)
                        .foregroundColor(.gray)
                } else {
                    ForEach(groupedExercises.keys.sorted(), id: \.self) { group in
                        NavigationLink(destination: WorkoutDetailView(group: group, lastWorkoutGroup: $lastWorkoutGroup)) {
                            HStack {
                                // Placeholder for the image
                                Image(systemName: "photo")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .cornerRadius(8)
                                
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
                print("Groups: \(groupedExercises.keys.sorted())")
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
        case "Stretch":
            return "Just Let It Go"
        case "Calisthenics":
            return "" // No subtitle in the screenshot
        default:
            return ""
        }
    }
    
    private func formattedDate(for group: String) -> String {
        if group == "Stretch" {
            return "Apr 9, 2025 10:09AM"
        }
        return "Feb 1, 2023 10:31PM"
    }
}
