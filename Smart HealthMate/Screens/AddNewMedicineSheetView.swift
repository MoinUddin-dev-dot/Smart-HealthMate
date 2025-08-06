import SwiftUI
import SwiftData

struct AddNewMedicineSheetView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authManager: AuthManager // Assuming AuthManager exists and is provided
    var onSave: (Medicine) -> Void

    @Binding var medicineToEdit: Medicine?

    @State private var name: String = ""
    @State private var purpose: String = ""
    @State private var dosage: String = ""
    @State private var selectedTimings: [Date] = [] // Holds the Date objects for scheduled times
    @State private var newTimeToAdd: Date = {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
        return calendar.date(from: components) ?? Date()
    }()

    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var isActive: Bool = true

    @State private var showAlert = false
    @State private var alertMessage = ""

    @Query private var userSettingsQuery: [UserSettings] // Assuming UserSettings model exists

    private func currentUserSettings() -> UserSettings {
        if let settings = userSettingsQuery.first(where: { $0.userID == authManager.currentUserUID }) {
            print("✅ 🔍 alreadyd new UserSettings with ID: \(settings.userID ?? "nil")")

            return settings
        } else {
            let newSettings = UserSettings(userID: authManager.currentUserUID ?? "unknown", userName: authManager.currentUserDisplayName)
            modelContext.insert(newSettings)
            do {
                try modelContext.save()
                print("✅ 🔍 Created and saved new UserSettings with ID: \(newSettings.userID ?? "nil")")
            } catch {
                print("❌ Failed to save new UserSettings: \(error.localizedDescription)")
            }
            return newSettings

        }
    }

    init(medicineToEdit: Binding<Medicine?>, onSave: @escaping (Medicine) -> Void) {
        self._medicineToEdit = medicineToEdit
        self.onSave = onSave
    }

    private func loadMedicineForEditing(_ medicine: Medicine?) {
        print("AddNewMedicineSheetView: loadMedicineForEditing called. Medicine: \(medicine?.name ?? "nil")")

        guard let medicine = medicine else {
            name = ""
            purpose = ""
            dosage = ""
            selectedTimings = []
            startDate = Calendar.current.startOfDay(for: Date())
            endDate = Calendar.current.startOfDay(for: Date())
            isActive = true
            return
        }

        name = medicine.name
        purpose = medicine.purpose
        dosage = medicine.dosage
        // FIX: Safely unwrap `scheduledDoses` and map their `time` property
        selectedTimings = medicine.scheduledDoses?.map { $0.time }.sorted() ?? []

        startDate = Calendar.current.startOfDay(for: medicine.startDate)

        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())

        if medicine.hasPeriodEnded() && !medicine.isActive {
            endDate = startOfToday
        } else {
            endDate = Calendar.current.startOfDay(for: medicine.endDate)
        }

        isActive = medicine.isActive
        print(" - Name: \(name)")
        print(" - Dosage: \(dosage)")
        print(" - Purpose: \(purpose)")
        print(" - Initial Active state from medicine: \(isActive)")
        print(" - Timings count: \(selectedTimings.count)")
        if !selectedTimings.isEmpty {
            print(" - First timing: \(AddNewMedicineSheetView.timeFormatter.string(from: selectedTimings.first!))")
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Medicine Details")) {
                    TextField("Medicine Name", text: $name)
                        .accessibilityIdentifier("medicine")
                    TextField("Purpose (e.g., Blood Pressure Control)", text: $purpose)
                        .accessibilityIdentifier("purpose")
                    TextField("Dosage (e.g., 5mg)", text: $dosage)
                        .accessibilityIdentifier("dosage")
                }

                Section(header: Text("Treatment Period")) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .onChange(of: startDate) { _, newDate in
                            let normalizedNewDate = Calendar.current.startOfDay(for: newDate)
                            if Calendar.current.startOfDay(for: endDate) < normalizedNewDate {
                                endDate = normalizedNewDate
                            }
                            startDate = normalizedNewDate
                        }

                    DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .onChange(of: endDate) { _, newDate in
                            endDate = Calendar.current.startOfDay(for: newDate)
                        }
                        .accessibilityIdentifier("endDatePicker")
                }

                Section(header: Text("Status")) {
                    Toggle("Is Active", isOn: $isActive)
                }

                Section(header: Text("Scheduled Timings")) {
                    if selectedTimings.isEmpty {
                        Text("No timings added yet.")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(selectedTimings.sorted(), id: \.self) { time in
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

                    VStack(alignment: .leading) {
                        HStack {
                            Text("Add New Time")
                            Spacer()
                            DatePicker(
                                "",
                                selection: $newTimeToAdd,
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .onChange(of: newTimeToAdd) { _, newDate in
                                let calendar = Calendar.current
                                let components = calendar.dateComponents([.hour, .minute], from: newDate)
                                if let todayAtNewTime = calendar.date(bySettingHour: components.hour!, minute: components.minute!, second: 0, of: Date()) {
                                    newTimeToAdd = todayAtNewTime
                                }
                            }
                        }

                        Button(action: {
                            let calendar = Calendar.current
                            let newTimeComponents = calendar.dateComponents([.hour, .minute], from: newTimeToAdd)

                            let isDuplicate = selectedTimings.contains { existingTime in
                                let existingTimeComponents = calendar.dateComponents([.hour, .minute], from: existingTime)
                                return newTimeComponents.hour == existingTimeComponents.hour && newTimeComponents.minute == existingTimeComponents.minute
                            }

                            if !isDuplicate {
                                selectedTimings.append(newTimeToAdd)
                                newTimeToAdd = Date() // Reset for next entry
                            } else {
                                alertMessage = "This time has already been added!"
                                showAlert = true
                            }
                        }) {
                            Label("Add Timing", systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .accessibilityIdentifier("timing")
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle(medicineToEdit == nil ? "Add New Medicine" : "Edit Medicine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        medicineToEdit = nil
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveMedicine()
                    }
                    .accessibilityIdentifier("save")
                }
            }
            .alert("Error", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                print("AddNewMedicineSheetView: .onAppear called.")
                loadMedicineForEditing(medicineToEdit)
            }
            .onChange(of: medicineToEdit) { _, newMedicine in
                print("AddNewMedicineSheetView: .onChange(of: medicineToEdit) called.")
                loadMedicineForEditing(newMedicine)
            }
        }
    }

    private func saveMedicine() {
        // --- Input Validation ---
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertMessage = "Medicine name cannot be empty."
            showAlert = true
            return
        }
        guard !purpose.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertMessage = "Purpose cannot be empty."
            showAlert = true
            return
        }
        guard !dosage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertMessage = "Dosage cannot be empty."
            showAlert = true
            return
        }
        guard !selectedTimings.isEmpty else {
            alertMessage = "Please add at least one scheduled timing."
            showAlert = true
            return
        }

        let normalizedStartDate = Calendar.current.startOfDay(for: startDate)
        let normalizedEndDate = Calendar.current.startOfDay(for: endDate)

        guard normalizedStartDate <= normalizedEndDate else {
            alertMessage = "Start date cannot be after end date."
            showAlert = true
            return
        }

        // 🆕 Create ScheduledDose objects from the selectedTimings (Dates)
        let newScheduledDoses = selectedTimings.sorted().map { time in
            return ScheduledDose(time: time) // No isTaken property needed here
        }

        var medicineToSave: Medicine

        print("DEBUG: Current AuthManager UID: \(authManager.currentUserUID ?? "nil")")

        if let existingMedicine = medicineToEdit {
            existingMedicine.name = name
            existingMedicine.purpose = purpose
            existingMedicine.dosage = dosage
            // Removed timingString
            existingMedicine.startDate = normalizedStartDate
            existingMedicine.endDate = normalizedEndDate
            existingMedicine.lastModifiedDate = Date()

            // 🆕 Handle scheduledDoses: Clear old ones and add new ones
            // SwiftData will automatically handle deletion from the context when the relationship is modified
            existingMedicine.scheduledDoses = [] // Clear existing dose templates
            existingMedicine.scheduledDoses = newScheduledDoses // Assign new dose templates
            newScheduledDoses.forEach { $0.medicine = existingMedicine } // Set inverse relationship for each new dose

            // Active/Inactive logic for existing medicine
            let currentDay = Calendar.current.startOfDay(for: Date())
            if existingMedicine.isActive && (normalizedEndDate < currentDay || normalizedStartDate > currentDay) {
                existingMedicine.isActive = false
                if normalizedEndDate < currentDay {
                    existingMedicine.inactiveDate = normalizedEndDate
                } else {
                    // Medicine made inactive because start date is in future
                    existingMedicine.inactiveDate = nil // Or you can set it to the new start date if you prefer
                }
            } else if !existingMedicine.isActive && normalizedEndDate >= currentDay && normalizedStartDate <= currentDay {
                existingMedicine.isActive = true
                existingMedicine.inactiveDate = nil
            }

            medicineToSave = existingMedicine

        } else { // Adding a new medicine
            medicineToSave = Medicine(
                id: UUID(),
                name: name,
                purpose: purpose,
                dosage: dosage,
                startDate: normalizedStartDate,
                endDate: normalizedEndDate,
                isActive: isActive,
                lastModifiedDate: Date(),
            )

            medicineToSave.userSettings = currentUserSettings()
            print("DEBUG: New medicine '\(medicineToSave.name)' linked to user: \(medicineToSave.userSettings?.userID ?? "nil")")

            // 🆕 Attach the newScheduledDoses to Medicine
            medicineToSave.scheduledDoses = newScheduledDoses
            newScheduledDoses.forEach { $0.medicine = medicineToSave } // Set inverse relationship

            // Active/Inactive logic for new medicine
            let currentDay = Calendar.current.startOfDay(for: Date())
            if medicineToSave.isActive && (normalizedEndDate < currentDay || normalizedStartDate > currentDay) {
                medicineToSave.isActive = false
                if normalizedEndDate < currentDay {
                    medicineToSave.inactiveDate = normalizedEndDate
                } else {
                    medicineToSave.inactiveDate = nil
                }
            } else if !medicineToSave.isActive && normalizedEndDate >= currentDay && normalizedStartDate <= currentDay {
                medicineToSave.isActive = true
                medicineToSave.inactiveDate = nil
            }


            modelContext.insert(medicineToSave)
        }

        do {
            try modelContext.save()
            print("Medicine saved to SwiftData: '\(medicineToSave.name)' with isActive: \(medicineToSave.isActive). Linked UserID: \(medicineToSave.userSettings?.userID ?? "nil")")
        } catch {
            print("Error saving medicine to SwiftData: \(error.localizedDescription)")
            alertMessage = "Failed to save medicine: \(error.localizedDescription)"
            showAlert = true
            return
        }

        onSave(medicineToSave)
        print("DEBUG: Calling onSave for '\(medicineToSave.name)' with final isActive: \(medicineToSave.isActive)")
        medicineToEdit = nil
        dismiss()
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}
