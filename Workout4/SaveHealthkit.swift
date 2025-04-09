//
//  SaveHealthkit.swift
//  Workout4
//
//  Created by Warren Hansen on 4/9/25.
//

import SwiftData
import SwiftUI
//import HealthKit
//
//func saveHIITWorkout(timeElapsed: Int, caloriesBurned: Double) {
//    let healthStore = HKHealthStore()
//    
//    guard HKHealthStore.isHealthDataAvailable() else { return }
//    
//    let workoutType = HKObjectType.workoutType()
//    let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
//    
//    healthStore.requestAuthorization(toShare: [workoutType, energyType], read: nil) { success, error in
//        if success {
//            let startDate = Date().addingTimeInterval(-Double(timeElapsed))
//            let endDate = Date()
//            
//            let energyQuantity = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: caloriesBurned)
//            let workout = HKWorkout(
//                activityType: .highIntensityIntervalTraining,
//                start: startDate,
//                end: endDate,
//                duration: Double(timeElapsed),
//                totalEnergyBurned: energyQuantity,
//                totalDistance: nil,
//                device: nil,
//                metadata: nil
//            )
//            
//            healthStore.save(workout) { success, error in
//                if let error = error {
//                    print("Error saving workout: \(error)")
//                }
//            }
//        }
//    }
//}
