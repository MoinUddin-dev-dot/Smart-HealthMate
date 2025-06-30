// AuthenticationView.swift - NO CHANGES needed from the last version.
// Just confirm that the `withAnimation` block is around the `isUserLoggedIn = true` line.

import SwiftUI

struct AuthenticationView: View {
    @Binding var isUserLoggedIn: Bool

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoginMode = true

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 25) {
                Spacer()
                VStack(spacing: 10) {
                    Image(systemName: "cross.case.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.white)
                    Text("Smart HealthMate")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .shadow(radius: 5)

                Spacer()

                VStack(spacing: 15) {
                    TextField("Email", text: $email)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(10)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .placeholder(when: email.isEmpty) { Text("Email").foregroundColor(.gray).padding(.leading) }

                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(10)
                        .placeholder(when: password.isEmpty) { Text("Password").foregroundColor(.gray).padding(.leading) }

                    if !isLoginMode {
                        SecureField("Confirm Password", text: $confirmPassword)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(10)
                            .placeholder(when: confirmPassword.isEmpty) { Text("Confirm Password").foregroundColor(.gray).padding(.leading) }
                    }

                    Button(action: {
                        // THIS IS THE CRUCIAL PART: The withAnimation block
                        withAnimation(.easeInOut(duration: 0.7)) { // Match duration from App.swift
                            if isLoginMode {
                                print("Attempting to log in with \(email) and \(password)")
                                isUserLoggedIn = true
                            } else {
                                if password == confirmPassword {
                                    print("Attempting to sign up with \(email), \(password)")
                                    isUserLoggedIn = true
                                } else {
                                    print("Passwords do not match!")
                                }
                            }
                        }
                    }) {
                        Text(isLoginMode ? "Login" : "Sign Up")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.accentColor)
                            .cornerRadius(10)
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal, 25)
                .padding(.vertical, 30)
                .background(Color.white.opacity(0.3))
                .cornerRadius(20)
                .shadow(radius: 10)

                Spacer()

                Button(action: {
                    isLoginMode.toggle()
                    email = ""
                    password = ""
                    confirmPassword = ""
                }) {
                    Text(isLoginMode ? "Don't have an account? Sign Up" : "Already have an account? Login")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.bottom, 30)
                }
            }
        }
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView(isUserLoggedIn: .constant(false))
    }
}
