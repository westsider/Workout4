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
    
    var body: some View {
        NavigationView {
            if history.isEmpty {
                Text("No History!")
                    .font(.title)
                    .foregroundColor(.gray)
            } else {
                List(history) { entry in
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
                .navigationTitle("History")
            }
        }
    }
}
