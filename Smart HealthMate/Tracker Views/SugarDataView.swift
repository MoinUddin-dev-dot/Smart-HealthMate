//
//  SugarDataView.swift
//  Smart HealthMate
//
//  Created by Moin on 6/18/25.
//

import SwiftUI
import SwiftData

struct SugarDataView: View {
    
    @Query(sort: [SortDescriptor(\VitalReading.date, order: .forward), SortDescriptor(\VitalReading.time, order: .forward)])
    private var vitals: [VitalReading] // SwiftData automatically keeps this up-to-date
    
    private var latestSugar: VitalReading? {
        vitals.filter { $0.type == .sugar }.last
    }

        var body: some View {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.orange) // Jaise image mein orange hai
                HStack {
                    Image(systemName: "calendar") // Example icon
                        .foregroundColor(.white)
                    VStack(alignment: .leading) {
                        Text("\(latestSugar?.sugarLevel ?? 0)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("Sugar (mg/dL)")
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
//    SugarDataView(value: 131)
//        .padding()
//}
