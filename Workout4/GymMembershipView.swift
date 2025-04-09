//
//  GymMembershipView.swift
//  Workout4
//
//  Created by Warren Hansen on 4/9/25.
//

import SwiftData
import SwiftUI

struct GymMembershipView: View {
    @State var dateNow: Date = Date()
    var body: some View {
        ZStack {
            Image("pfAll")
                .resizable()

            Text("\(dateNow.formatted(date: .abbreviated, time: .omitted))")
                .font(.system(size: 28, design: .serif)).fontWeight(.heavy)
                .foregroundStyle(.white)
                .background(.black)
                .offset(CGSize(width: 0.0, height: -290))
               
        }
        .edgesIgnoringSafeArea(.all)
        .ignoresSafeArea()
        .onAppear() {
            dateNow = Date()
        }
    }
}

#Preview {
    GymMembershipView()
}
