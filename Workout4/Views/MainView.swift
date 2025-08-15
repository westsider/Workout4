//
//  ContentView.swift
//  Workout4
//
//  Created by Warren Hansen on 4/9/25.
//  https://x.com/i/grok?conversation=1909994612581614019
// /Users/warrenhansen/Documents/xCode_2025/Workout4

import SwiftUI
import SwiftData

struct MainView: View {
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
            
            // Request HealthKit authorization
            // Delay the request to avoid immediate crash if Info.plist not configured
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                HealthKitManager.shared.requestAuthorization { authorized in
                    if authorized {
                        print("HealthKit authorization granted")
                    } else {
                        print("HealthKit authorization denied or not available")
                    }
                }
            }
        }
    }
    
    private func loadInitialData() {
        // Check if data is already loaded to avoid duplicates
        let fetchDescriptor = FetchDescriptor<Exercise>()
        do {
            let existingExercises = try modelContext.fetch(fetchDescriptor)
            if existingExercises.isEmpty {
                // Load the JSON file from the bundle
                loadExercisesFromJSON()
            } else {
                print("Data already loaded: \(existingExercises.count) exercises")
                // Check if we need to force reload (for development/updates)
                checkForDataUpdate(existingCount: existingExercises.count)
            }
        } catch {
            print("Error checking existing exercises: \(error)")
        }
    }
    
    private func loadExercisesFromJSON() {
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
    }
    
    private func checkForDataUpdate(existingCount: Int) {
        var needsUpdate = false
        
        // Check if "Decline Sit Up" exists in Deep Horizon
        let declineDescriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate<Exercise> { exercise in
                exercise.group == "Deep Horizon" && exercise.name == "Decline Sit Up"
            }
        )
        
        // Check if "Barbell Curl" exists in Falcon
        let barbellDescriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate<Exercise> { exercise in
                exercise.group == "Falcon" && exercise.name == "Barbell Curl"
            }
        )
        
        // Check if "BB Upright Row" exists in Trident (checking for Trident updates)
        let tridentDescriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate<Exercise> { exercise in
                exercise.group == "Trident" && exercise.name == "BB Upright Row"
            }
        )
        
        do {
            let declineSitUps = try modelContext.fetch(declineDescriptor)
            let barbellCurls = try modelContext.fetch(barbellDescriptor)
            let bbUprightRows = try modelContext.fetch(tridentDescriptor)
            
            if declineSitUps.isEmpty {
                print("Decline Sit Up not found in Deep Horizon")
                needsUpdate = true
            }
            
            if barbellCurls.isEmpty {
                print("Barbell Curl not found in Falcon")
                needsUpdate = true
            }
            
            if bbUprightRows.isEmpty {
                print("BB Upright Row not found in Trident")
                needsUpdate = true
            }
            
            if needsUpdate {
                print("Updates needed, forcing data reload...")
                forceReloadData()
            }
        } catch {
            print("Error checking for updates: \(error)")
        }
    }
    
    private func forceReloadData() {
        // Delete all existing exercises
        let fetchDescriptor = FetchDescriptor<Exercise>()
        do {
            let existingExercises = try modelContext.fetch(fetchDescriptor)
            for exercise in existingExercises {
                modelContext.delete(exercise)
            }
            try modelContext.save()
            print("Deleted \(existingExercises.count) existing exercises")
            
            // Now reload from JSON
            loadExercisesFromJSON()
            print("Reloaded exercises from JSON")
        } catch {
            print("Error during force reload: \(error)")
        }
    }
}

#Preview {
    MainView()
        .modelContainer(for: [Exercise.self, WorkoutHistory.self], inMemory: true)
}
