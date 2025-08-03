//
//  Workout4App.swift
//  Workout4
//
//  Created by Warren Hansen on 4/9/25.
//

import SwiftUI
import SwiftData

//@main
//struct Workout4App: App {
//    var sharedModelContainer: ModelContainer = {
//        let schema = Schema([
//            Item.self,
//        ])
//        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
//
//        do {
//            return try ModelContainer(for: schema, configurations: [modelConfiguration])
//        } catch {
//            fatalError("Could not create ModelContainer: \(error)")
//        }
//    }()
//
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//        }
//        .modelContainer(sharedModelContainer)
//    }
//}

@main
struct WorkoutApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
                .modelContainer(for: [Exercise.self, WorkoutHistory.self])
        }
    }
}
