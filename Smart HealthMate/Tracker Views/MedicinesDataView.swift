//
//  MedicinesDataView.swift
//  Smart HealthMate
//
//  Created by Moin on 6/18/25.
//

import SwiftUI

struct MedicinesDataView: View {
    let count: Int // Example parameter
        var body: some View {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue) // Jaise image mein blue hai
                HStack {
                    Image(systemName: "pill.fill") // Example icon
                        .foregroundColor(.white)
                    VStack(alignment: .leading) {
                        Text("\(count)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("Medicines")
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
    MedicinesDataView(count: 2)
        .padding()
}
