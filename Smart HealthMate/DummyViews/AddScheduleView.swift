//
//  AddScheduleView.swift
//  Smart HealthMate
//
//  Created by Moin on 6/23/25.
//

import SwiftUI
import SwiftData


struct AddScheduleView: View {
    var medication: Medication
    var onDone: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    
    @State private var time = Date()
    @State private var dosage = ""
    @State private var allSchedules: [MedicationSchedule] = []

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Add Schedule")) {
                    DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                    TextField("Dosage Instruction", text: $dosage)
                    
                    Button("Add Time Slot") {
                        let schedule = MedicationSchedule(medication: medication, time: time, dosageInstruction: dosage)
                        context.insert(schedule)
                        allSchedules.append(schedule)
                        dosage = ""
                    }
                    .disabled(dosage.isEmpty)
                }
                
                Section(header: Text("Scheduled Times")) {
                    ForEach(allSchedules, id: \.time) { s in
                        HStack {
                            Text(s.time.formatted(date: .omitted, time: .shortened))
                            Spacer()
                            Text(s.dosageInstruction)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("Schedule Times")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        try? context.save()
                        onDone()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        context.delete(medication) // remove incomplete med if canceled
                        dismiss()
                    }
                }
            }
        }
    }
}


//#Preview {
//    AddScheduleView(medication: <#Medication#>, onDone: <#() -> Void#>)
//}
