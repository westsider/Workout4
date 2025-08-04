//
//  SaveHealthkit.swift
//  Workout4
//
//  Created by Warren Hansen on 4/9/25.
//

import SwiftData
import SwiftUI
import HealthKit

class HealthKitManager {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()
    
    private init() {}
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false)
            return
        }
        
        let typesToShare: Set<HKSampleType> = [
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        
        let typesToRead: Set<HKObjectType> = []
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            if let error = error {
                print("HealthKit authorization error: \(error)")
            }
            completion(success)
        }
    }
    
    func saveWorkout(group: String, timeElapsed: Int, completion: @escaping (Bool) -> Void) {
        // Calculate calories based on workout type and duration
        let caloriesBurned = calculateCalories(for: group, duration: timeElapsed)
        
        // Determine workout activity type based on group
        let activityType = workoutActivityType(for: group)
        
        let startDate = Date().addingTimeInterval(-Double(timeElapsed))
        
        // Create workout configuration
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = activityType
        
        // Create workout builder
        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: configuration, device: nil)
        
        // Start the workout
        builder.beginCollection(withStart: startDate) { success, error in
            if let error = error {
                print("Error starting workout collection: \(error)")
                completion(false)
                return
            }
            
            // Add energy burned sample
            let energyBurned = HKQuantity(unit: .kilocalorie(), doubleValue: caloriesBurned)
            let energySample = HKQuantitySample(
                type: HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
                quantity: energyBurned,
                start: startDate,
                end: Date()
            )
            
            builder.add([energySample]) { success, error in
                if let error = error {
                    print("Error adding energy sample: \(error)")
                }
                
                // Add metadata
                builder.addMetadata([
                    "WorkoutGroup": group,
                    "IncludedStretch": true
                ]) { success, error in
                    if let error = error {
                        print("Error adding metadata: \(error)")
                    }
                    
                    // Finish the workout
                    builder.endCollection(withEnd: Date()) { success, error in
                        if let error = error {
                            print("Error ending workout collection: \(error)")
                            completion(false)
                            return
                        }
                        
                        // Finish and save the workout
                        builder.finishWorkout { workout, error in
                            if let error = error {
                                print("Error finishing workout: \(error)")
                                completion(false)
                            } else {
                                print("Successfully saved workout to HealthKit")
                                completion(true)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func calculateCalories(for group: String, duration: Int) -> Double {
        // Average calories burned per minute for different workout types
        // These are estimates and can be adjusted based on user preferences
        let caloriesPerMinute: Double
        
        switch group.lowercased() {
        case "falcon", "deep horizon", "challenger", "trident":
            // High-intensity strength training
            caloriesPerMinute = 8.0
        case "calisthenics":
            // Bodyweight exercises
            caloriesPerMinute = 6.0
        case "stretch":
            // Light stretching
            caloriesPerMinute = 2.5
        default:
            // Default moderate intensity
            caloriesPerMinute = 5.0
        }
        
        return caloriesPerMinute * Double(duration) / 60.0
    }
    
    private func workoutActivityType(for group: String) -> HKWorkoutActivityType {
        switch group.lowercased() {
        case "falcon", "deep horizon", "challenger", "trident":
            return .traditionalStrengthTraining
        case "calisthenics":
            return .functionalStrengthTraining
        case "stretch":
            return .flexibility
        default:
            return .other
        }
    }
}
