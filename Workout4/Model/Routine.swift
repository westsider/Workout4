//
//  Routine.swift
//  Workout4
//
//  Created by Warren Hansen on 4/9/25.
//


import Foundation
import SwiftData
import SwiftUI

struct Routine: Codable {
    let exercises: [ExerciseJSON]
}

struct ExerciseJSON: Codable {
    let id: String
    let group: String
    let name: String
    let numReps: Int
    let numSets: Int
    let weight: Int
    let completed: Bool
    let date: String
    let timeElapsed: Int
}

func loadExercises(from jsonString: String, context: ModelContext) {
    let decoder = JSONDecoder()
    do {
        let data = jsonString.data(using: .utf8)!
        let routines = try decoder.decode([String: [ExerciseJSON]].self, from: data)
        
        for (_, exercises) in routines {
            for exerciseJSON in exercises {
                let dateFormatter = ISO8601DateFormatter()
                let date = dateFormatter.date(from: exerciseJSON.date) ?? Date()
                
                let exercise = Exercise(
                    id: exerciseJSON.id,
                    group: exerciseJSON.group,
                    name: exerciseJSON.name,
                    numReps: exerciseJSON.numReps,
                    numSets: exerciseJSON.numSets,
                    weight: exerciseJSON.weight,
                    completed: exerciseJSON.completed,
                    date: date,
                    timeElapsed: exerciseJSON.timeElapsed
                )
                context.insert(exercise)
            }
        }
    } catch {
        print("Error decoding JSON: \(error)")
    }
}
