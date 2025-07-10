//
//  AddNewMedicineSheetView.swift
//  Smart HealthMate
//
//  Created by Moin on 6/18/25.
//
import SwiftUI
import SwiftData


// MARK: - AddNewMedicineSheetView (Updated with compact DatePicker for better UX)

struct AddNewMedicineSheetView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext // Inject model context
    var onSave: (Medicine) -> Void

    @Binding var medicineToEdit: Medicine? // Binding for the medicine being edited

    @State private var name: String = ""
    @State private var purpose: String = ""
    @State private var dosage: String = ""
    @State private var selectedTimings: [Date] = []
    @State private var newTimeToAdd: Date = {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
        return calendar.date(from: components) ?? Date()
    }()

    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    
    @State private var isActive: Bool = true // User's desired active state

    @State private var showAlert = false
    @State private var alertMessage = ""

    // Custom initializer to accept a Binding for medicineToEdit
    init(medicineToEdit: Binding<Medicine?>, onSave: @escaping (Medicine) -> Void) {
        self._medicineToEdit = medicineToEdit
        self.onSave = onSave
    }

    private func loadMedicineForEditing(_ medicine: Medicine?) {
        print("AddNewMedicineSheetView: loadMedicineForEditing called. Medicine: \(medicine?.name ?? "nil")")

        guard let medicine = medicine else {
            // Reset states for adding a new medicine
            name = ""
            purpose = ""
            dosage = ""
            selectedTimings = []
            startDate = Calendar.current.startOfDay(for: Date())
            endDate = Calendar.current.startOfDay(for: Date())
            isActive = true // Default to active for new medicine
            return
        }
        
        // Load existing medicine data into state variables
        name = medicine.name
        purpose = medicine.purpose
        dosage = medicine.dosage
        
        // FIX: Safely unwrap `scheduledDoses` and map `time` property
        selectedTimings = medicine.scheduledDoses?.map { $0.time }.sorted() ?? []
        
        startDate = Calendar.current.startOfDay(for: medicine.startDate)
        
        // When loading for editing, if it's inactive and its period has ended,
        // display the end date as today's start of day, or the actual end date
        // if it's still in the past or future. This helps avoid confusing dates.
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())

        if medicine.hasPeriodEnded() && !medicine.isActive {
            endDate = startOfToday // If ended and inactive, show today as the logical end for display
        } else {
            endDate = calendar.startOfDay(for: medicine.endDate)
        }
        
        isActive = medicine.isActive // Load existing active state from the medicine
        
        print("  - Name: \(name)")
        print("  - Dosage: \(dosage)")
        print("  - Purpose: \(purpose)")
        print("  - Initial Active state from medicine: \(isActive)")
        print("  - Timings count: \(selectedTimings.count)")
        if !selectedTimings.isEmpty {
            print("  - First timing: \(AddNewMedicineSheetView.timeFormatter.string(from: selectedTimings.first!))")
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Medicine Details")) {
                    TextField("Medicine Name", text: $name)
                    TextField("Purpose (e.g., Blood Pressure Control)", text: $purpose)
                    TextField("Dosage (e.g., 5mg)", text: $dosage)
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
                                newTimeToAdd = Date() // Reset for next addition
                            } else {
                                alertMessage = "This time has already been added!"
                                showAlert = true
                            }
                        }) {
                            Label("Add Timing", systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle(medicineToEdit == nil ? "Add New Medicine" : "Edit Medicine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        medicineToEdit = nil // Clear editing state on cancel
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveMedicine()
                    }
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
            // Use .task for loading data when the sheet appears or medicineToEdit changes
            // .task is generally preferred over .onChange for initial data loading in sheets
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

        // Create ScheduledDose objects for the relationship
        // These are not yet inserted into the modelContext. They will be inserted
        // automatically when assigned to the `medicineToSave`'s `scheduledDoses` property.
        let scheduledDoses = selectedTimings.sorted().map { time in
            return ScheduledDose(time: time, isTaken: false)
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let timingStringForMedicine = selectedTimings.sorted().map { formatter.string(from: $0) }.joined(separator: ", ")

        var medicineToSave: Medicine // This will be the SwiftData managed object

        if let existingMedicine = medicineToEdit { // Editing an existing medicine
            // Update the properties of the existing SwiftData managed object
            existingMedicine.name = name
            existingMedicine.purpose = purpose
            existingMedicine.dosage = dosage
            existingMedicine.timingString = timingStringForMedicine
            existingMedicine.startDate = normalizedStartDate
            existingMedicine.endDate = normalizedEndDate
            existingMedicine.lastModifiedDate = Date()

            // Handle scheduledDoses: Clear old ones and add new ones
            // SwiftData will automatically handle deletion from the context when the relationship is modified
            // This assumes your ScheduledDose relationship in Medicine is configured for cascade delete.
            // If not, you might need to manually delete old doses from modelContext.
            existingMedicine.scheduledDoses = [] // Clear existing doses
            existingMedicine.scheduledDoses = scheduledDoses // Assign new doses
            scheduledDoses.forEach { $0.medicine = existingMedicine } // Set inverse relationship for each new dose

            // --- MANUAL / DATE-BASED ACTIVE/INACTIVE LOGIC (Existing Medicine) ---
            
            // Scenario 1: User explicitly turns OFF the "Is Active" toggle (Manual Deactivation)
            if !isActive && existingMedicine.isActive { // Toggle was OFF AND it was previously active
                existingMedicine.isActive = false
                existingMedicine.inactiveDate = Date() // Set inactive date to now
                print("DEBUG: Medicine '\(existingMedicine.name)' manually deactivated during edit. isActive: \(existingMedicine.isActive), inactiveDate: \(String(describing: existingMedicine.inactiveDate))")
                showAlert = false // Clear any previous alerts if this is a manual deactivation
            }
            // Scenario 2: User tries to set it ACTIVE, but dates prevent it (Auto-Deactivation/Future Activation)
            else if isActive && !existingMedicine.isCurrentlyActiveBasedOnDates {
                existingMedicine.isActive = false // Override to inactive
                if existingMedicine.isFutureMedicine { // Check if it's future
                    existingMedicine.inactiveDate = nil // Clear inactiveDate for future meds
                    let formattedStartDate = AddNewMedicineSheetView.itemFormatter.string(from: existingMedicine.startDate)
                    alertMessage = "Medicine saved! It will become active on its start date (\(formattedStartDate))."
                } else if existingMedicine.hasPeriodEnded() { // Check if period ended
                    existingMedicine.inactiveDate = existingMedicine.inactiveDate ?? Date() // Set inactive date if not already
                    alertMessage = "Medicine saved! It has already passed its end date and is now inactive."
                }
                showAlert = true
                print("DEBUG: Medicine '\(existingMedicine.name)' auto-deactivated during edit due to dates. isActive: \(existingMedicine.isActive)")
            }
            // Scenario 3: User turns ON the "Is Active" toggle (Manual Activation) AND dates allow it
            else if isActive && !existingMedicine.isActive && existingMedicine.isCurrentlyActiveBasedOnDates {
                existingMedicine.isActive = true
                existingMedicine.inactiveDate = nil // Clear inactive date on activation
                print("DEBUG: Medicine '\(existingMedicine.name)' manually activated. isActive: \(existingMedicine.isActive)")
                showAlert = false // Clear any previous alerts if this is a manual activation
            }
            // Scenario 4: User left toggle as is (true or false) and no date conflicts (for existing medicine)
            else {
                existingMedicine.isActive = isActive // Set to the toggle's value
                if !isActive {
                    existingMedicine.inactiveDate = existingMedicine.inactiveDate ?? Date() // Ensure it has a date if it's now inactive
                } else {
                    existingMedicine.inactiveDate = nil // Ensure it's nil if it's active
                }
                print("DEBUG: Medicine '\(existingMedicine.name)' active state maintained from toggle. isActive: \(existingMedicine.isActive)")
                showAlert = false // No conflict, clear alert
            }
            medicineToSave = existingMedicine // The existing object is already managed by SwiftData

        } else { // Adding a new medicine
            // Initialize new SwiftData Medicine object
            medicineToSave = Medicine( // Directly initialize into medicineToSave
                id: UUID(), // Use UUID() for new objects
                name: name,
                purpose: purpose,
                dosage: dosage,
                timingString: timingStringForMedicine,
                startDate: normalizedStartDate,
                endDate: normalizedEndDate,
                isActive: isActive, // Start with user's toggle value
                lastModifiedDate: Date()
            )

            medicineToSave.scheduledDoses = scheduledDoses // Attach ScheduledDoses to Medicine
            scheduledDoses.forEach { $0.medicine = medicineToSave } // Set inverse relationship for each dose
            modelContext.insert(medicineToSave) // Insert the new Medicine object into the model context
            
            // --- MANUAL / DATE-BASED ACTIVE/INACTIVE LOGIC FOR NEW MEDICINE ---
            
            // Scenario A: User explicitly creates it as INACTIVE (toggle was off)
            if !medicineToSave.isActive {
                medicineToSave.inactiveDate = Date() // Set inactive date to now
                print("DEBUG: New medicine '\(medicineToSave.name)' created as inactive. isActive: \(medicineToSave.isActive)")
            }
            // Scenario B: User creates it as ACTIVE, but dates prevent it (Auto-Deactivation/Future Activation)
            else if medicineToSave.isActive && !medicineToSave.isCurrentlyActiveBasedOnDates {
                medicineToSave.isActive = false // Override to inactive
                if medicineToSave.isFutureMedicine { // Check if it's future
                    medicineToSave.inactiveDate = nil // Clear inactiveDate for future meds
                    let formattedStartDate = AddNewMedicineSheetView.itemFormatter.string(from: medicineToSave.startDate)
                    alertMessage = "Medicine saved! It will become active on its start date (\(formattedStartDate))."
                } else if medicineToSave.hasPeriodEnded() { // Check if period ended
                    medicineToSave.inactiveDate = Date() // Set inactive date to now
                    alertMessage = "Medicine saved! It has already passed its end date and is now inactive."
                }
                showAlert = true
                print("DEBUG: New medicine '\(medicineToSave.name)' auto-deactivated due to dates. isActive: \(medicineToSave.isActive)")
            }
            // Scenario C: User creates it as ACTIVE and dates allow it
            else { // medicineToSave.isActive is true AND medicineToSave.isCurrentlyActiveBasedOnDates is true
                medicineToSave.inactiveDate = nil // Ensure inactiveDate is nil for new active meds
                print("DEBUG: New medicine '\(medicineToSave.name)' created as active. isActive: \(medicineToSave.isActive)")
            }
        }
        
        // The onSave closure is likely used to update the UI in the parent view,
        // and should receive the SwiftData managed object.
        onSave(medicineToSave) // This calls the closure in MedicineListView
        print("DEBUG: Calling onSave for '\(medicineToSave.name)' with final isActive: \(medicineToSave.isActive)")
        medicineToEdit = nil // Clear the binding to reset the sheet state
        dismiss()
    }
    
    // DateFormatters are static properties for efficiency
    private static let itemFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}

//#Preview {
//    AddNewMedicineSheetView()
//}
