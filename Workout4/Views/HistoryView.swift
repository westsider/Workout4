//
//  HistoryView.swift
//  Workout4
//
//  Created by Warren Hansen on 4/9/25.
//

import SwiftData
import SwiftUI

struct HistoryView: View {
    // Sort by date in descending order (newest first)
    @Query(sort: \WorkoutHistory.date, order: .reverse) private var history: [WorkoutHistory]
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationView {
            if history.isEmpty {
                Text("No History!")
                    .font(.title)
                    .foregroundColor(.gray)
            } else {
                List {
                    ForEach(history) { entry in
                        VStack(alignment: .leading) {
                            Text(entry.group)
                                .font(.headline)
                            HStack{
                                Text(entry.date, style: .date)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text("\(entry.timeElapsed / 60) minutes")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .onDelete(perform: deleteWorkout)
                }
                .navigationTitle("History")
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
