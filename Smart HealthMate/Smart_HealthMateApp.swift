//
//  Smart_HealthMateApp.swift
//  Smart HealthMate
//
//  Created by Moin on 6/18/25.
//

import SwiftUI
import SwiftData

@main
struct Smart_HealthMateApp: App {
    
    @State var isUserLoggedIn: Bool = false
    var body: some Scene {
        WindowGroup {
                    Group {
                        if isUserLoggedIn {
                            MedicineTracker()
                                .id("MedicineTrackerView") // Assign a unique ID
                                // This transition applies when MedicineTracker APPEARS
                                // It slides in from the trailing (right) edge
                                .transition(.move(edge: .trailing))
                        } else {
                            AuthenticationView(isUserLoggedIn: $isUserLoggedIn)
                                .id("AuthenticationView") // Assign a unique ID
                                // This transition applies when AuthenticationView DISAPPEARS
                                // It slides out to the leading (left) edge
                                .transition(.move(edge: .leading))
                        }
                    }
                    // THIS ANIMATION MODIFIER APPLIES TO THE *CHANGE* OF THE GROUP'S CONTENT
                    // and tells the .transition how to animate.
                    .animation(.easeInOut(duration: 0.7), value: isUserLoggedIn) // Increased duration to make it more obvious
                }
        .modelContainer(for: [User.self, Medication.self, MedicationLog.self, SugarLog.self, MedicationSchedule.self, ChatMessage.self, BPLog.self, AIInsight.self] )
    }
}
