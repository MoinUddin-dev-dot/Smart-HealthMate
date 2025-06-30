//
//  MedicationLogView.swift
//  Smart HealthMate
//
//  Created by Moin on 6/23/25.
//

import SwiftUI
struct MedicationLogView: View {
    let schedule: MedicationSchedule
    @Environment(\.modelContext) private var context
    
    var body: some View {
        VStack {
            Text("Medicine at \(formattedTime(schedule.time))")
            
            Button("✅ Mark as Taken") {
                let log = MedicationLog(schedule: schedule, scheduledTime: Date(), taken: true, takenAt: Date())
                context.insert(log)
                try? context.save()
            }
            
            Button("❌ Mark as Missed") {
                let log = MedicationLog(schedule: schedule, scheduledTime: Date(), taken: false)
                context.insert(log)
                try? context.save()
            }
        }
        .navigationTitle("Log Dose")
    }
    
    func formattedTime(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.timeStyle = .short
        return fmt.string(from: date)
    }
}

