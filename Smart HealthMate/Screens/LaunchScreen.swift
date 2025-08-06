//
//  LaunchScreen.swift
//  Smart HealthMate
//
//  Created by Moin on 7/31/25.
//

import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            // Background color
            Color.white
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                // The logo image. You should add this image to your Assets.xcassets.
                // Assuming the image name is "healthmate_logo".
                Image("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200) // Adjust size as needed

                VStack(spacing: 5) {
                    Text("HEALTHMATE")
                        .font(.custom("HelveticaNeue-Bold", size: 30)) // Or any other bold font
                        .foregroundColor(.black)

                    Text("YOUR WELLNESS COMPANION")
                        .font(.custom("HelveticaNeue-Light", size: 16)) // Or a light font
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

// You can use this for a preview in Xcode
struct LaunchScreenView_Previews: PreviewProvider {
    static var previews: some View {
        LaunchScreenView()
    }
}
