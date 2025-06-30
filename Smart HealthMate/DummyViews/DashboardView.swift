//
//  DashboardView.swift
//  Smart HealthMate
//
//  Created by Moin on 6/23/25.
//

import SwiftUI

struct DashboardView: View {
    let user: User
    
    var body: some View {
        List {
            Section(header: Text("👤 User Info")) {
                Text("Name: \(user.name)")
                Text("Email: \(user.email)")
            }
            
            Section(header: Text("💊 Medication")) {
                NavigationLink("➕ Add Medicine", destination: AddMedicineView(user: user))
                NavigationLink("📋 View Your Medicines", destination: UserMedicinesView(user: user))
            }
        }
        .navigationTitle("Dashboard")
    }
}

