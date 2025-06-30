//
//  UserMedicinesView.swift
//  Smart HealthMate
//
//  Created by Moin on 6/23/25.
//

import SwiftUI
import SwiftData

struct UserMedicinesView: View {
    @Environment(\.modelContext) private var context
    let user: User
    @Query private var allMeds: [Medication]
    
    var body: some View {
        let meds = allMeds.filter { $0.user?.email == user.email }
        
        List {
            ForEach(meds) { med in
                Section(header: Text(med.name)) {
                    Text("Purpose: \(med.purpose)")
                    Text("Duration: \(med.durationDays) days")
                    
                    if med.schedules.count > 1 {
                        Text("Dosage: \(med.schedules.count) times daily")
                    } else {
                        Text("Dosage: Once daily")
                    }
                    
                    ForEach(med.schedules) { schedule in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("⏰ \(formattedTime(schedule.time))")
                                .font(.subheadline)
                            
                            let todayLogs = schedule.logs.filter {
                                Calendar.current.isDate($0.scheduledTime, inSameDayAs: Date())
                            }
                            let taken = todayLogs.filter { $0.taken }.count
                            let missed = todayLogs.filter { !$0.taken }.count
                            
                            Text("Taken: \(taken), Missed: \(missed)")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            // 👉 Add navigation to log screen here
                            NavigationLink("Log Dose", destination: MedicationLogView(schedule: schedule))
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    context.delete(meds[index])
                }
            }
        }
        .navigationTitle("Your Medicines")
    }
    
    func formattedTime(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.timeStyle = .short
        return fmt.string(from: date)
    }
}

