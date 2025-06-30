//
//  DetailView.swift
//  Smart HealthMate
//
//  Created by Moin on 6/18/25.
//

import SwiftUI

struct DetailView: View {
    let imageName: String
    var body: some View {
        VStack {
            Text("You tapped:")
                .font(.headline)
            Image(systemName: imageName)
                .font(.largeTitle)
                .padding()
            Text("This is a new view for the '\(imageName)' icon.")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .navigationTitle(imageName.capitalized)
        .padding()
    }
}

#Preview {
    DetailView(imageName: "paperclip")
}
