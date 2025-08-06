//
//  BPDataView.swift
//  Smart HealthMate
//
//  Created by Moin on 6/18/25.
//

import SwiftUI
import  SwiftData

struct BPDataView: View {
    @Query(sort: [SortDescriptor(\VitalReading.date, order: .forward), SortDescriptor(\VitalReading.time, order: .forward)])
    private var vitals: [VitalReading] // SwiftData automatically keeps this up-to-date

    private var latestBP: VitalReading? {
        vitals.filter { $0.type == .bp }.last
    }
    
    let systolic: Int
       let diastolic: Int
       var body: some View {
           ZStack(alignment: .leading) {
               RoundedRectangle(cornerRadius: 10)
                   .fill(Color.purple) // Jaise image mein purple hai
               HStack {
                   Image(systemName: "heart.fill") // Example icon
                       .foregroundColor(.white)
                   VStack(alignment: .leading) {
                       Text("\(latestBP?.systolic ?? 0)/\(latestBP?.diastolic ?? 0)")
                           .font(.title)
                           .fontWeight(.bold)
                           .foregroundColor(.white)
                       Text("BP (mmHg)")
                           .font(.subheadline)
                           .foregroundColor(.white)
                   }
               }
               .padding()
           }
           .fixedSize(horizontal: false, vertical: true)
       }
}


//#Preview {
//    BPDataView(systolic: 120, diastolic: 80)
//        .padding()
//}
