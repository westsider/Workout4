//
//  HistoryView.swift
//  Workout4
//
//  Created by Warren Hansen on 4/9/25.
//

import SwiftData
import SwiftUI
import Charts

struct HistoryView: View {
    // Sort by date in descending order (newest first)
    @Query(sort: \WorkoutHistory.date, order: .reverse) private var history: [WorkoutHistory]
    @Environment(\.modelContext) private var modelContext
    
    var dailyCaloriesData: [DailyCalories] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Create array for last 14 days
        var dailyData: [DailyCalories] = []
        
        for dayOffset in (0..<14).reversed() {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                // Filter workouts for this specific day
                let dayWorkouts = history.filter { workout in
                    calendar.isDate(workout.date, inSameDayAs: date)
                }
                
                // Sum calories for the day
                let totalCalories = dayWorkouts.compactMap { $0.caloriesBurned }.reduce(0, +)
                
                dailyData.append(DailyCalories(date: date, calories: totalCalories))
            }
        }
        
        return dailyData
    }
    
    var maxCalories: Double {
        dailyCaloriesData.map { $0.calories }.max() ?? 100
    }
    
    @ViewBuilder
    var chartView: some View {
        Chart(dailyCaloriesData) { item in
            BarMark(
                x: .value("Date", item.date, unit: .day),
                y: .value("Calories", item.calories)
            )
            .foregroundStyle(item.calories > 0 ? Color(red: 0.33, green: 0.42, blue: 0.18) : Color.clear)
        }
        .frame(height: 150)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.day(), anchor: .top)
                    .font(.system(size: 10))
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine()
                AxisValueLabel()
                    .font(.caption2)
            }
        }
        .chartYScale(domain: 0...(maxCalories > 0 ? maxCalories * 1.1 : 100))
    }
    
    var body: some View {
        NavigationView {
            if history.isEmpty {
                Text("No History!")
                    .font(.title)
                    .foregroundColor(.gray)
            } else {
                VStack(spacing: 0) {
                    // Bar Graph
                    VStack(alignment: .leading, spacing: 8) {
                        chartView
                            .padding(.horizontal)
                    }
                    .padding(.vertical)
                    .background(Color(UIColor.systemGroupedBackground))
                    
                    // History List
                    List {
                        ForEach(history) { entry in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.group)
                                    .font(.headline)
                                HStack {
                                    Text(entry.date, style: .date)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    Spacer()
                                    VStack(alignment: .trailing) {
                                        Text("\(entry.timeElapsed / 60) min")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                        if let calories = entry.caloriesBurned {
                                            Text("\(Int(calories)) cal")
                                                .font(.subheadline)
                                                .foregroundColor(.orange)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        .onDelete(perform: deleteWorkout)
                    }
                }
                .navigationTitle("HISTORY")
                .navigationBarTitleDisplayMode(.large)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbarBackground(Color(red: 0.28, green: 0.40, blue: 0.25), for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
            }
        }
    }
    
    private func deleteWorkout(at offsets: IndexSet) {
        for index in offsets {
            let workout = history[index]
            modelContext.delete(workout)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Error deleting workout: \(error)")
        }
    }
}

struct DailyCalories: Identifiable {
    let id = UUID()
    let date: Date
    let calories: Double
}
