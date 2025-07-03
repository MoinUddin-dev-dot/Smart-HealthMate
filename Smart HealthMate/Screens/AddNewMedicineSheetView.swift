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

    @Binding var medicineToEdit: Medicine?

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
            isActive = true // Default to active for new
            return
        }
        
        name = medicine.name
        purpose = medicine.purpose
        dosage = medicine.dosage
        selectedTimings = medicine.scheduledDoses.map { $0.time }.sorted()
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
                                newTimeToAdd = Date()
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
                        medicineToEdit = nil
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
            .onChange(of: medicineToEdit) { _, newMedicine in
                print("AddNewMedicineSheetView: .onChange(of: medicineToEdit) called.")
                loadMedicineForEditing(newMedicine)
            }
        }
    }

    private func saveMedicine() {
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

        let scheduledDoses = selectedTimings.sorted().map { time in
            Medicine.ScheduledDose(id: UUID(), time: time, isTaken: false)
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let timingStringForMedicine = selectedTimings.sorted().map { formatter.string(from: $0) }.joined(separator: ", ")

        var savedMedicine: Medicine
        if let existingMedicine = medicineToEdit { // Editing an existing medicine
            // Initialize savedMedicine with properties from UI and existing, *before* applying specific logic
            savedMedicine = Medicine(
                id: existingMedicine.id,
                name: name,
                purpose: purpose,
                dosage: dosage,
                timingString: timingStringForMedicine,
                scheduledDoses: scheduledDoses,
                startDate: normalizedStartDate,
                endDate: normalizedEndDate,
                isActive: isActive, // Use the UI toggle state directly here
                inactiveDate: existingMedicine.inactiveDate, // Carry over existing inactiveDate initially
                lastModifiedDate: Date()
            )
            
            // --- MANUAL / DATE-BASED ACTIVE/INACTIVE LOGIC ---
            
            // Scenario 1: User explicitly turns OFF the "Is Active" toggle (Manual Deactivation)
            // This is the most important one for your current bug.
            if !isActive && existingMedicine.isActive { // Toggle was OFF AND it was previously active
                savedMedicine.isActive = false
                savedMedicine.inactiveDate = Date() // Set inactive date to now
                print("DEBUG: Medicine '\(savedMedicine.name)' manually deactivated during edit. isActive: \(savedMedicine.isActive), inactiveDate: \(String(describing: savedMedicine.inactiveDate))")
                showAlert = false // Clear any previous alerts if this is a manual deactivation
            }
            // Scenario 2: User tries to set it ACTIVE, but dates prevent it (Auto-Deactivation/Future Activation)
            // This happens if isActive is true, but `isCurrentlyActiveBasedOnDates` is false.
            else if isActive && !savedMedicine.isCurrentlyActiveBasedOnDates {
                savedMedicine.isActive = false // Override to inactive
                if savedMedicine.isFutureMedicine { // Check if it's future
                    savedMedicine.inactiveDate = nil // Clear inactiveDate for future meds
                    let formattedStartDate = AddNewMedicineSheetView.itemFormatter.string(from: savedMedicine.startDate)
                    alertMessage = "Medicine saved! It will become active on its start date (\(formattedStartDate))."
                } else if savedMedicine.hasPeriodEnded() { // Check if period ended
                    savedMedicine.inactiveDate = savedMedicine.inactiveDate ?? Date() // Set inactive date if not already
                    alertMessage = "Medicine saved! It has already passed its end date and is now inactive."
                }
                showAlert = true
                print("DEBUG: Medicine '\(savedMedicine.name)' auto-deactivated during edit due to dates. isActive: \(savedMedicine.isActive)")
            }
            // Scenario 3: User turns ON the "Is Active" toggle (Manual Activation) AND dates allow it
            // This covers re-activating from the inactive list or from a date-based inactivation.
            else if isActive && !existingMedicine.isActive && savedMedicine.isCurrentlyActiveBasedOnDates {
                savedMedicine.isActive = true
                savedMedicine.inactiveDate = nil // Clear inactive date on activation
                print("DEBUG: Medicine '\(savedMedicine.name)' manually activated. isActive: \(savedMedicine.isActive)")
                showAlert = false // Clear any previous alerts if this is a manual activation
            }
            // Scenario 4: User left toggle as is (true or false) and no date conflicts (for existing medicine)
            // This ensures `inactiveDate` is managed if `isActive` (from toggle) is false but not scenario 1,
            // or cleared if `isActive` is true but not scenario 3.
            else {
                // If isActive is false from the toggle (and it was already inactive or just became inactive)
                if !isActive {
                    savedMedicine.inactiveDate = savedMedicine.inactiveDate ?? Date() // Ensure it has a date if it's now inactive
                } else { // If isActive is true from the toggle (and no date conflicts)
                    savedMedicine.inactiveDate = nil // Ensure it's nil if it's active
                }
                print("DEBUG: Medicine '\(savedMedicine.name)' active state maintained from toggle. isActive: \(savedMedicine.isActive)")
            }
            
        } else { // Adding a new medicine
            // Initialize new medicine with properties from UI toggle state
            savedMedicine = Medicine(
                id: UUID(),
                name: name,
                purpose: purpose,
                dosage: dosage,
                timingString: timingStringForMedicine,
                scheduledDoses: scheduledDoses,
                startDate: normalizedStartDate,
                endDate: normalizedEndDate,
                isActive: isActive, // Start with user's toggle value
                lastModifiedDate: Date()
            )
            
            // --- MANUAL / DATE-BASED ACTIVE/INACTIVE LOGIC FOR NEW MEDICINE ---
            
            // Scenario A: User explicitly creates it as INACTIVE (toggle was off)
            if !savedMedicine.isActive {
                savedMedicine.inactiveDate = Date() // Set inactive date to now
                print("DEBUG: New medicine '\(savedMedicine.name)' created as inactive. isActive: \(savedMedicine.isActive)")
            }
            // Scenario B: User creates it as ACTIVE, but dates prevent it (Auto-Deactivation/Future Activation)
            else if savedMedicine.isActive && !savedMedicine.isCurrentlyActiveBasedOnDates {
                savedMedicine.isActive = false // Override to inactive
                if savedMedicine.isFutureMedicine { // Check if it's future
                    savedMedicine.inactiveDate = nil // Clear inactiveDate for future meds
                    let formattedStartDate = AddNewMedicineSheetView.itemFormatter.string(from: savedMedicine.startDate)
                    alertMessage = "Medicine saved! It will become active on its start date (\(formattedStartDate))."
                } else if savedMedicine.hasPeriodEnded() { // Check if period ended
                    savedMedicine.inactiveDate = Date() // Set inactive date to now
                    alertMessage = "Medicine saved! It has already passed its end date and is now inactive."
                }
                showAlert = true
                print("DEBUG: New medicine '\(savedMedicine.name)' auto-deactivated due to dates. isActive: \(savedMedicine.isActive)")
            }
            // Scenario C: User creates it as ACTIVE and dates allow it
            else { // savedMedicine.isActive is true AND savedMedicine.isCurrentlyActiveBasedOnDates is true
                savedMedicine.inactiveDate = nil // Ensure inactiveDate is nil for new active meds
                print("DEBUG: New medicine '\(savedMedicine.name)' created as active. isActive: \(savedMedicine.isActive)")
            }
        }
        
        onSave(savedMedicine) // This calls the closure in MedicineListView
        print("DEBUG: Calling onSave for '\(savedMedicine.name)' with final isActive: \(savedMedicine.isActive)")
        medicineToEdit = nil
        dismiss()
    }
    
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
