//
//  MainView.swift
//  Smart HealthMate
//
//  Created by Moin on 6/23/25.
//

import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var context
    @Query private var allUsers: [User]
    
    @State private var name = ""
    @State private var email = ""
    @State private var activeUser: User?
    @State private var navigate = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("🧑‍⚕️ Welcome to Smart HealthMate")
                    .font(.title2)
                
                TextField("Enter your name", text: $name)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Enter your email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.emailAddress)
                
                Button("🚀 Continue") {
                    loginOrCreateUser()
                    
                }
                .disabled(name.isEmpty || email.isEmpty)
                .buttonStyle(.borderedProminent)
                
                
                if let user = activeUser {
                    NavigationLink(
                        destination: DashboardView(user: user),
                        isActive: $navigate
                    ) {
                        EmptyView()
                    }
                }
                
            }
            .padding()
        }
    }
    
    func loginOrCreateUser() {
        if let existing = allUsers.first(where: { $0.email.lowercased() == email.lowercased() }) {
            print("✅ Existing user found")
            activeUser = existing
            DispatchQueue.main.async {
                        navigate = true
                    }
        } else {
            let newUser = User(email: email, name: name)
            context.insert(newUser)
            try? context.save()
            activeUser = newUser
            DispatchQueue.main.async {
                        navigate = true
                    }
        }
    }
}

