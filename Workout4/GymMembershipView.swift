//
//  GymMembershipView.swift
//  Workout4
//
//  Created by Warren Hansen on 4/9/25.
//

import SwiftData
import SwiftUI

struct GymMembershipView: View {
    var body: some View {
        VStack {
            Text("Warren Hansen")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Apr 9, 2025")
                .font(.title2)
                .foregroundColor(.gray)
            
            Image(systemName: "qrcode") // Placeholder for QR code
                .resizable()
                .frame(width: 200, height: 200)
                .padding()
            
            Text("3103824522")
                .font(.title3)
            
            Text("PF Black Card® Membership")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Have an awesome workout, Warren! You got this!")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding()
            
            Spacer()
        }
        .navigationTitle("Club Pass")
    }
}
