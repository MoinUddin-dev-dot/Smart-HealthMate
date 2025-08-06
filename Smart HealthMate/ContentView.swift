//
//  ContentView.swift
//  Smart HealthMate
//
//  Created by Moin on 6/18/25.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showSecondScreen = false

    var body: some View {
        Group {
            if showSecondScreen {
                if authManager.isLoggedIn {
                    if authManager.isEmailVerified {
                        MedicineTracker()
                            .id("MedicineTrackerView")
                            .transition(.move(edge: .trailing))// User is logged in and email verified
                    } else {
                        VerifyEmailView() // User is logged in but email not verified
                    }
                } else {
                    LoginView()
                        .id("AuthenticationView")
                        .transition(.move(edge: .leading))// User is not logged in
                }
            } else {
                LaunchScreenView()
                    .onAppear{
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                                    withAnimation {
                                                        showSecondScreen = true
                                                    }
                                                }
                    }
            }
        }
//        .animation(.easeInOut(duration: 0.7), value: true) // Increased duration to make it more obvious
        // Optional: Show a loading indicator if auth state is still being determined
        .overlay {
            if authManager.isLoading {
                ProgressView("Loading...")
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .alert(item: $authManager.errorMessage) { errorMessage in
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
    }
}

//#Preview {
//    ContentView()
//}
