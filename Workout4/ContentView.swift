//
//  ContentView.swift
//  Workout4
//
//  Created by Warren Hansen on 4/9/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var lastWorkoutGroup: String?
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            TrainingPlanView(lastWorkoutGroup: $lastWorkoutGroup)
                .tabItem {
                    Label("Home", systemImage: "list.bullet")
                }
            
            GymMembershipView()
                .tabItem {
                    Label("Membership", systemImage: "person.fill")
                }
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
        }
        .onAppear {
            // Load last workout group from UserDefaults
            lastWorkoutGroup = UserDefaults.standard.string(forKey: "lastWorkoutGroup")
            
            // Load exercises from the JSON file
            loadInitialData()
        }
    }
    
    private func loadInitialData() {
        // Check if data is already loaded to avoid duplicates
        let fetchDescriptor = FetchDescriptor<Exercise>()
        do {
            let existingExercises = try modelContext.fetch(fetchDescriptor)
            if existingExercises.isEmpty {
                // Load the JSON file from the bundle
                if let url = Bundle.main.url(forResource: "exercise", withExtension: "json") {
                    do {
                        let data = try Data(contentsOf: url)
                        let jsonString = String(data: data, encoding: .utf8)
                        if let jsonString = jsonString {
                            loadExercises(from: jsonString, context: modelContext)
                        } else {
                            print("Error: Could not convert JSON data to string")
                        }
                    } catch {
                        print("Error loading JSON file: \(error)")
                    }
                } else {
                    print("Error: Could not find exercise.json in the bundle")
                }
            } else {
                print("Data already loaded: \(existingExercises.count) exercises")
            }
        } catch {
            print("Error checking existing exercises: \(error)")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
