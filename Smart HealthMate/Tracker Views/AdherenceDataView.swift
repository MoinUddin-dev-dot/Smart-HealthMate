//
//  DataView.swift
//  Smart HealthMate
//
//  Created by Moin on 6/18/25.
//

import SwiftUI

struct AdherenceDataView: View {
    let adherencePercentage: Int
    var body: some View {
        
        
        
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.green)
            
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.white)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(adherencePercentage)%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Adherence")
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
    AdherenceDataView(adherencePercentage: 85)
        .padding()
        
}
