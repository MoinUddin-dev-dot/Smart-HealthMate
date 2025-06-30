//
//  AddMedicineView.swift
//  Smart HealthMate
//
//  Created by Moin on 6/23/25.
//

import SwiftUI
import SwiftData
struct AddMedicineView: View {
    @Environment(\.modelContext) private var context
    let user: User  // 👈 Pass current user
    
    @State private var medName = ""
    @State private var purpose = ""
    @State private var durationDays = 7
    @State private var selectedTimes: [Date] = [Date()]
    
    var body: some View {
        Form {
            TextField("Medicine Name", text: $medName)
            TextField("Purpose", text: $purpose)
            Stepper("Duration (Days): \(durationDays)", value: $durationDays, in: 1...90)
            
            Section(header: Text("Dosage Times")) {
                ForEach(selectedTimes.indices, id: \.self) { index in
                    DatePicker("Time", selection: $selectedTimes[index], displayedComponents: .hourAndMinute)
                }
                Button("➕ Add Time") {
                    selectedTimes.append(Date())
                }
            }
            
            Button("💊 Save Medicine") {
                let med = Medication(name: medName, purpose: purpose, durationDays: durationDays, startDate: Date(), user: user)
                context.insert(med)
                
                for time in selectedTimes {
                    let schedule = MedicationSchedule(medication: med, time: time, dosageInstruction: "\(medName) at \(formattedTime(time))")
                    context.insert(schedule)
                }
                
                try? context.save()
            }
        }
        .navigationTitle("Add Medicine")
    }
    
    func formattedTime(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.timeStyle = .short
        return fmt.string(from: date)
    }
}

