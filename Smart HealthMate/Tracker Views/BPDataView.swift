//
//  BPDataView.swift
//  Smart HealthMate
//
//  Created by Moin on 6/18/25.
//

import SwiftUI

struct BPDataView: View {
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
                       Text("\(systolic)/\(diastolic)")
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


#Preview {
    BPDataView(systolic: 120, diastolic: 80)
        .padding()
}
