//
//  SugarDataView.swift
//  Smart HealthMate
//
//  Created by Moin on 6/18/25.
//

import SwiftUI

struct SugarDataView: View {
    let value: Int
        var body: some View {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.orange) // Jaise image mein orange hai
                HStack {
                    Image(systemName: "calendar") // Example icon
                        .foregroundColor(.white)
                    VStack(alignment: .leading) {
                        Text("\(value)")
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

#Preview {
    SugarDataView(value: 131)
        .padding()
}
