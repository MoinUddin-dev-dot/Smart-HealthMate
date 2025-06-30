//
//  AddNewMedicineSheetView.swift
//  Smart HealthMate
//
//  Created by Moin on 6/18/25.
//
import SwiftUI

// MARK: - AddNewMedicineSheetView (Updated with compact DatePicker for better UX)
struct AddNewMedicineSheetView: View {
    @Environment(\.dismiss) var dismiss
    var onSave: (Medicine) -> Void

    @State private var name: String = ""
    @State private var purpose: String = ""
    @State private var dosage: String = ""

    // Use an array of Dates to store individual selected timings
    @State private var selectedTimings: [Date] = []
    // State to hold the new time selected in the DatePicker before adding to list
    @State private var newTimeToAdd: Date = {
        // Initialize with current hour/minute, but clean seconds/milliseconds
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
        return calendar.date(from: components) ?? Date()
    }()


    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Medicine Details")) {
                    TextField("Medicine Name", text: $name)
                    TextField("Purpose (e.g., Blood Pressure Control)", text: $purpose)
                    TextField("Dosage (e.g., 5mg)", text: $dosage)
                }

                Section(header: Text("Scheduled Timings")) {
                    // List of currently added timings
                    if selectedTimings.isEmpty {
                        Text("No timings added yet.")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(selectedTimings.sorted(), id: \.self) { time in // Sort for consistent display
                            HStack {
                                Text(time, style: .time)
                                Spacer()
                                Button(action: {
                                    selectedTimings.removeAll(where: { $0 == time })
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }

                    // DatePicker for adding new timings - now with .compact style
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Add New Time")
                            Spacer()
                            DatePicker(
                                "", // Empty label to align with other form elements
                                selection: $newTimeToAdd,
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden() // Hide default label as we have our own
                            .datePickerStyle(.compact) // Use .compact style for a smaller, inline appearance
                            .onChange(of: newTimeToAdd) { newDate in
                                // When the date picker changes, ensure it's on a current-day context for accurate time comparison later
                                let calendar = Calendar.current
                                let components = calendar.dateComponents([.hour, .minute], from: newDate)
                                if let todayAtNewTime = calendar.date(bySettingHour: components.hour!, minute: components.minute!, second: 0, of: Date()) {
                                    newTimeToAdd = todayAtNewTime
                                }
                            }
                        } // End of HStack for DatePicker and label

                        Button(action: {
                            // Add time only if it's not already in the list
                            let calendar = Calendar.current
                            let newTimeComponents = calendar.dateComponents([.hour, .minute], from: newTimeToAdd)

                            let isDuplicate = selectedTimings.contains { existingTime in
                                let existingTimeComponents = calendar.dateComponents([.hour, .minute], from: existingTime)
                                return newTimeComponents.hour == existingTimeComponents.hour && newTimeComponents.minute == existingTimeComponents.minute
                            }

                            if !isDuplicate {
                                selectedTimings.append(newTimeToAdd)
                                // Reset newTimeToAdd for next selection to current time or default
                                newTimeToAdd = Date() // Reset to current time after adding
                            } else {
                                // In a real app, you'd show a user-friendly alert
                                print("Time already added!")
                            }
                        }) {
                            Label("Add Timing", systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("Add New Medicine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Convert selectedTimings (array of Dates) into a comma-separated string
                        // This string is used by the Medicine initializer to create ScheduledDose objects.
                        let formatter = DateFormatter()
                        formatter.dateFormat = "h:mm a"
                        let timingStringForMedicine = selectedTimings.sorted().map { formatter.string(from: $0) }.joined(separator: ", ")

                        let newMedicine = Medicine(name: name, purpose: purpose, dosage: dosage, timingString: timingStringForMedicine)
                        onSave(newMedicine)
                        dismiss()
                    }
                    .disabled(name.isEmpty || purpose.isEmpty || dosage.isEmpty || selectedTimings.isEmpty)
                }
            }
        }
    }
}
//#Preview {
//    AddNewMedicineSheetView()
//}
