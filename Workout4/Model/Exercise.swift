//
//  Exercise.swift
//  Workout4
//
//  Created by Warren Hansen on 4/9/25.
//


import SwiftData
import SwiftUI

// Model for a single exercise
@Model
class Exercise: Identifiable {
    var id: String
    var group: String
    var name: String
    var numReps: Int
    var numSets: Int
    var weight: Int
    var completed: Bool
    var date: Date
    var timeElapsed: Int

    init(id: String, group: String, name: String, numReps: Int, numSets: Int, weight: Int, completed: Bool, date: Date, timeElapsed: Int) {
        self.id = id
        self.group = group
        self.name = name
        self.numReps = numReps
        self.numSets = numSets
        self.weight = weight
        self.completed = completed
        self.date = date
        self.timeElapsed = timeElapsed
    }
}

// Model for workout history
@Model
class WorkoutHistory: Identifiable {
    var id: String
    var group: String
    var date: Date
    var timeElapsed: Int
    var caloriesBurned: Double?

    init(id: String, group: String, date: Date, timeElapsed: Int, caloriesBurned: Double? = nil) {
        self.id = id
        self.group = group
        self.date = date
        self.timeElapsed = timeElapsed
        self.caloriesBurned = caloriesBurned
    }
}