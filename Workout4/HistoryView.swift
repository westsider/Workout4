//
//  HistoryView.swift
//  Workout4
//
//  Created by Warren Hansen on 4/9/25.
//

import SwiftData
import SwiftUI

struct HistoryView: View {
    @Query private var history: [WorkoutHistory]
    
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
                        Text(entry.date, style: .date)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text("Time Elapsed: \(entry.timeElapsed) seconds")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .navigationTitle("History")
            }
        }
    }
}
