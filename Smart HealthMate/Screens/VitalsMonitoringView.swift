////
////  VitalsMonitoringView.swift
////  Smart HealthMate
////
////  Created by Moin on 6/25/25.
////
//
//import SwiftUI
//
//// MARK: - 12. VitalsMonitoringView (NEW VIEW - Drag Gesture Removed)
//struct VitalsMonitoringView: View {
//    @Binding var isShowingPanelType: PanelType
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 20) {
//            HStack {
//                VStack(alignment: .leading) {
//                    Text("Vitals Monitoring")
//                        .font(.title2)
//                        .fontWeight(.semibold)
//
//                }
//                Spacer()
//                Button(action: {
//                    print("Add Reading tapped!")
//                    // Action to present a sheet for adding new readings
//                }) {
//                    Label("Add Reading", systemImage: "plus")
//                        .font(.subheadline)
//                        .fontWeight(.semibold)
//                        .padding(.vertical, 8)
//                        .padding(.horizontal, 12)
//                        .background(Color.purple) // Purple background as in image
//                        .foregroundColor(.white)
//                        .cornerRadius(8)
//                }
//            }
//            .padding(.bottom, 10)
//
//            // Blood Pressure Card
//            VitalsCardView(
//                title: "Blood Pressure",
//                latestReading: "120/80",
//                time: "9:00 AM",
//                unit: "mmHg",
////                status: "Normal",
//                iconName: "heart.fill",
//                tintColor: Color.red // Red tint for BP
//            )
//
//            // Blood Sugar Card
//            VitalsCardView(
//                title: "Blood Sugar",
//                latestReading: "140",
//                time: "8:30 AM",
//                unit: "mg/dL",
////                status: "Elevated",
//                iconName: "waveform.path.ecg.rectangle", // A more fitting sugar icon, though image uses wave
//                tintColor: Color.orange // Orange tint for Sugar
//            )
//
//            Spacer() // Pushes content to the top if there's extra space
//        }
//        .padding()
//        .background(Color.white) // Main panel background
//        .cornerRadius(20)
//        .shadow(radius: 5)
//        // MARK: - Removed: .gesture(DragGesture().onEnded { ... }) to allow parent ScrollView to respond
//    }
//}
//
//// MARK: - VitalsCardView (Helper View - Fixed "Middle Line")
//struct VitalsCardView: View {
//    let title: String
//    let latestReading: String
//    let time: String
//    let unit: String
////    let status: String
//    let iconName: String
//    let tintColor: Color
//
//    var body: some View {
//        ZStack(alignment: .leading) {
//            // 1. Overall Card Background with subtle tint
//            RoundedRectangle(cornerRadius: 12)
//                .fill(tintColor.opacity(0.05)) // Subtle tint for the entire card background
//
//            // 2. Left Border Line
//            RoundedRectangle(cornerRadius: 12)
//                .fill(tintColor) // Bold tint color for the border
//                .frame(width: 4)
//
//            // 3. Main Content VStack (all text, icons - NO SEPARATE WHITE BACKGROUND HERE)
//            VStack(alignment: .leading, spacing: 8) {
//                HStack {
//                    Image(systemName: iconName)
//                        .font(.subheadline)
//                        .foregroundColor(tintColor)
//                        .padding(6)
//                        .background(tintColor.opacity(0.15))
//                        .clipShape(Circle())
//
//                    VStack(alignment: .leading) {
//                        Text(title)
//                            .font(.subheadline)
//                            .foregroundColor(.gray)
//                        Text("Latest Reading")
//                            .font(.caption)
//                            .foregroundColor(.secondary)
//                    }
//                    Spacer()
//                }
//
//                Text(latestReading)
//                    .font(.largeTitle)
//                    .fontWeight(.bold)
//                    .foregroundColor(.primary)
//
//                HStack {
//                    Text(time)
//                        .font(.callout)
//                        .foregroundColor(.gray)
//                    Spacer()
//                    VStack(alignment: .trailing) {
//                        Text(unit)
//                            .font(.caption2)
//                            .foregroundColor(.gray)
////                        HStack(spacing: 2) {
////                            Image(systemName: "arrow.up.right")
////                                .font(.caption2)
////                                .rotationEffect(.degrees(45))
////                                .foregroundColor(status == "Normal" ? .green : .orange)
////                            Text(status)
////                                .font(.caption2)
////                                .fontWeight(.medium)
////                                .foregroundColor(status == "Normal" ? .green : .orange)
////                        }
//                    }
//                }
//            }
//            .padding(.leading, 15 + 4) // Adjust padding for the border + desired spacing
//            .padding(15) // General padding for content inside the card
//            // MARK: - REMOVED: .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
//            // Now, the VStack will inherit the subtle tint from the overall card background
//        }
//        .cornerRadius(12) // Overall card corner radius
//        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
//        .padding(.horizontal, 5) // Horizontal spacing from edges
//    }
//}
//
//
//// MARK: - VitalReading Struct (NEW)
//struct VitalReading: Identifiable, Equatable, Codable { // Added Codable for easier storage if needed
//    let id: UUID
//    let type: VitalType
//    var systolic: Int?
//    var diastolic: Int?
//    var sugarLevel: Int?
//    var date: Date // Changed to var so it can be updated for editing
//    var time: Date // Changed to Date to use DatePicker for time
//
//    enum VitalType: String, CaseIterable, Identifiable, Codable { // Added Codable
//        case bp = "bp"
//        case sugar = "sugar"
//        var id: String { self.rawValue }
//        var displayName: String {
//            switch self {
//            case .bp: return "Blood Pressure"
//            case .sugar: return "Blood Sugar"
//            }
//        }
//    }
//
//    init(id: UUID = UUID(), type: VitalType, systolic: Int? = nil, diastolic: Int? = nil, sugarLevel: Int? = nil, date: Date, time: Date) {
//        self.id = id
//        self.type = type
//        self.systolic = systolic
//        self.diastolic = diastolic
//        self.sugarLevel = sugarLevel
//        self.date = date
//        self.time = time
//    }
//
//    // Helper to determine simplified status for display
//    func getStatus() -> String {
//        switch type {
//        case .bp:
//            if let sys = systolic, let dias = diastolic {
//                if sys < 90 || dias < 60 { return "Low" }
//                if sys <= 120 && dias <= 80 { return "Normal" }
//                if sys > 120 || dias > 80 { return "Elevated" } // Any higher than normal is Elevated
//            }
//        case .sugar:
//            if let sugar = sugarLevel {
//                if sugar < 70 { return "Low" }
//                if sugar <= 100 { return "Normal" }
//                if sugar > 100 { return "Elevated" } // Any higher than normal is Elevated
//            }
//        }
//        return "N/A"
//    }
//
//    // Helper for tint color based on status
//    func getStatusColor() -> Color {
//        let status = getStatus()
//        switch vitalStatusCategory(status: status) {
//        case .normal: return .green
//        case .elevated: return .orange
//        case .low: return .blue
//        case .unknown: return .gray
//        }
//    }
//
//    private func vitalStatusCategory(status: String) -> VitalStatusCategory {
//        switch status {
//        case "Normal": return .normal
//        case "Elevated": return .elevated
//        case "Low": return .low
//        default: return .unknown
//        }
//    }
//
//    enum VitalStatusCategory {
//        case normal, low, elevated, unknown
//    }
//}
//
//
//
//// MARK: - VitalsMonitoringScreen (UPDATED)
//struct VitalsMonitoringScreen: View {
//    @Binding var vitals: [VitalReading] // Binding to the main vitals state
//    let medicinesCount: Int // Added for SMAMedicineTrackerStats
//    @State private var showingAddReadingSheet = false
//    @State private var showingEditReadingSheet = false
//    @State private var selectedVitalForEdit: VitalReading?
//    @State private var showingActionSheet = false
//    @State private var vitalToDelete: VitalReading?
//
//    private var latestBP: VitalReading? {
//        vitals.filter { $0.type == .bp }.last
//    }
//
//    private var latestSugar: VitalReading? {
//        vitals.filter { $0.type == .sugar }.last
//    }
//
//    var body: some View {
//        NavigationStack {
//            GeometryReader { geometry in
//                ScrollView(showsIndicators: false) {
//                    VStack(alignment: .leading, spacing: 20) {
//                        // Universal Header and Stats
//                        Text("Track your blood pressure and sugar levels")
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                            .padding(.horizontal, 20)
//                        SMAMedicineTrackerStats(medicinesCount: medicinesCount) // Use the passed count
//
//                        // Recent Readings Section
//                        Text("Recent Readings")
//                            .font(.title2)
//                            .fontWeight(.semibold)
//                            .padding(.top, 10)
//                            .padding(.horizontal)
//
//                        LazyVStack(spacing: 8) {
//                            if vitals.isEmpty {
//                                Text("No recent vital readings.")
//                                    .font(.subheadline)
//                                    .foregroundColor(.gray)
//                                    .padding()
//                                    .frame(maxWidth: .infinity)
//                                    .background(Color.gray.opacity(0.1))
//                                    .cornerRadius(12)
//                                    .padding(.horizontal)
//                            } else {
//                                ForEach(vitals.reversed()) { vital in // Show all, reversed for latest first
//                                    RecentVitalReadingRow(vital: vital)
//                                        .onLongPressGesture {
//                                            self.selectedVitalForEdit = vital
//                                            self.vitalToDelete = vital // Set for deletion as well
//                                            self.showingActionSheet = true
//                                        }
//                                }
//                            }
//                        }
//                        .padding(.bottom, 20)
//                    }
//                    .padding(.bottom, geometry.safeAreaInsets.bottom + 60)
//                }
//            }
//            .navigationTitle("Vitals Monitoring")
//            .navigationBarTitleDisplayMode(.large)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button(action: {
//                        showingAddReadingSheet = true
//                    }) {
//                        Label("Add Reading", systemImage: "plus")
//                    }
//                }
//            }
//            .sheet(isPresented: $showingAddReadingSheet) {
//                AddVitalReadingSheetView { newVital in
//                    vitals.append(newVital)
//                    // Sort vitals by date and then time
//                    vitals.sort {
//                        if $0.date == $1.date {
//                            return $0.time < $1.time
//                        }
//                        return $0.date < $1.date
//                    }
//                }
//            }
//            .sheet(isPresented: $showingEditReadingSheet) {
//                if let vitalToEdit = selectedVitalForEdit {
//                    EditVitalReadingSheetView(vital: vitalToEdit) { updatedVital in
//                        if let index = vitals.firstIndex(where: { $0.id == updatedVital.id }) {
//                            vitals[index] = updatedVital
//                            // Sort vitals by date and then time after edit
//                            vitals.sort {
//                                if $0.date == $1.date {
//                                    return $0.time < $1.time
//                                }
//                                return $0.date < $1.date
//                            }
//                        }
//                    }
//                }
//            }
//            .actionSheet(isPresented: $showingActionSheet) {
//                ActionSheet(
//                    title: Text("Vital Reading Options"),
//                    message: Text("What do you want to do with this reading?"),
//                    buttons: [
//                        .default(Text("Edit")) {
//                            showingEditReadingSheet = true
//                        },
//                        .destructive(Text("Delete")) {
//                            if let vital = vitalToDelete {
//                                deleteVital(vital)
//                            }
//                        },
//                        .cancel()
//                    ]
//                )
//            }
//            .onAppear(perform: cleanUpOldReadings)
//        }
//    }
//
//    private func cleanUpOldReadings() {
//        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date.distantPast
//        vitals = vitals.filter { $0.date >= thirtyDaysAgo }
//    }
//
//    private func deleteVital(_ vital: VitalReading) {
//        vitals.removeAll { $0.id == vital.id }
//    }
//}
//
//// MARK: - VitalSummaryCard (NEW)
//struct VitalSummaryCard: View {
//    let type: VitalReading.VitalType
//    var systolic: Int?
//    var diastolic: Int?
//    var sugarLevel: Int?
//    let time: Date // Changed to Date
//    // Simplified status for card view, remove if not needed for this card anymore
//    let status: String
//
//    // REMOVE these lines. They are the cause of the "Invalid redeclaration" error.
//    // let iconName: String
//    // let tintColor: Color
//
//    var body: some View {
//        RoundedRectangle(cornerRadius: 12)
//            .fill(
//                LinearGradient(
//                    gradient: Gradient(colors: [gradientStart, gradientEnd]),
//                    startPoint: .topLeading,
//                    endPoint: .bottomTrailing
//                )
//            )
//            .overlay(
//                RoundedRectangle(cornerRadius: 12)
//                    .stroke(tintColor.opacity(0.2), lineWidth: 1)
//            )
//            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
//            .frame(maxWidth: .infinity)
//            .aspectRatio(3/1, contentMode: .fit) // Adjusted aspect ratio for a more compact look
//            .overlay(
//                HStack(alignment: .center) {
//                    VStack(alignment: .leading) {
//                        Text(displayValue)
//                            .font(.title2)
//                            .fontWeight(.bold)
//                            .foregroundColor(tintColor.opacity(0.8))
//                        Text(type.displayName)
//                            .font(.subheadline)
//                            .foregroundColor(tintColor.opacity(0.6))
//                        Text(time, style: .time) // Displaying time using Date style
//                            .font(.caption)
//                            .foregroundColor(tintColor.opacity(0.5))
//                    }
//                    Spacer()
//                    Image(systemName: iconName) // This now correctly refers to the computed property
//                        .font(.title2)
//                        .padding(8)
//                        .background(tintColor.opacity(0.2))
//                        .clipShape(Circle())
//                        .foregroundColor(tintColor.opacity(0.7))
//                }
//                .padding(12) // Padding inside the card content
//            )
//    }
//
//    private var displayValue: String {
//        switch type {
//        case .bp:
//            return "\(systolic ?? 0)/\(diastolic ?? 0)"
//        case .sugar:
//            return "\(sugarLevel ?? 0)"
//        }
//    }
//
//    // These are the *correct* declarations for iconName and tintColor as computed properties
//    private var iconName: String {
//        switch type {
//        case .bp: return "heart.fill"
//        case .sugar: return "waveform.path.ecg"
//        }
//    }
//
//    private var tintColor: Color {
//        switch type {
//        case .bp: return .red
//        case .sugar: return .orange
//        }
//    }
//
//    private var gradientStart: Color {
//        switch type {
//        case .bp: return .red.opacity(0.05)
//        case .sugar: return .orange.opacity(0.05)
//        }
//    }
//
//    private var gradientEnd: Color {
//        switch type {
//        case .bp: return .red.opacity(0.1)
//        case .sugar: return .orange.opacity(0.1)
//        }
//    }
//}
//
//// MARK: - RecentVitalReadingRow (NEW)
//struct RecentVitalReadingRow: View {
//    let vital: VitalReading
//
//    var body: some View {
//        HStack {
//            Image(systemName: vital.type == .bp ? "heart.fill" : "waveform.path.ecg")
//                .foregroundColor(vital.type == .bp ? .red : .orange)
//                .font(.body)
//                .frame(width: 30, height: 30)
//                .background(vital.type == .bp ? Color.red.opacity(0.1) : Color.orange.opacity(0.1))
//                .clipShape(Circle())
//
//            VStack(alignment: .leading) {
//                Text(vital.type.displayName)
//                    .font(.headline)
//                    .fontWeight(.medium)
//                Text("\(vital.date, formatter: Self.dateFormatter) at \(vital.time, formatter: Self.timeFormatter)") // Use formatters for date and time
//                    .font(.caption)
//                    .foregroundColor(.gray)
//            }
//
//            Spacer()
//
//            VStack(alignment: .trailing) {
//                Text(displayValue)
//                    .font(.headline)
//                    .fontWeight(.bold)
//                Text(vital.type == .bp ? "mmHg" : "mg/dL")
//                    .font(.caption)
//                    .foregroundColor(.gray)
//                // Display status and color
////                HStack(spacing: 2) {
////                    Image(systemName: vital.getStatus() == "Normal" ? "checkmark.circle.fill" : "exclamationmark.triangle.fill") // Simpler icons for simplified status
////                        .font(.caption2)
////                        .foregroundColor(vital.getStatusColor())
////                    Text(vital.getStatus())
////                        .font(.caption2)
////                        .fontWeight(.medium)
////                        .foregroundColor(vital.getStatusColor())
////                }
//            }
//        }
//        .padding(12)
//        .background(Color.white)
//        .cornerRadius(10)
//        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
//        .padding(.horizontal)
//    }
//
//    private var displayValue: String {
//        switch vital.type {
//        case .bp:
//            return "\(vital.systolic ?? 0)/\(vital.diastolic ?? 0)"
//        case .sugar:
//            return "\(vital.sugarLevel ?? 0)"
//        }
//    }
//
//    private static let dateFormatter: DateFormatter = {
//        let formatter = DateFormatter()
//        formatter.dateStyle = .medium
//        formatter.timeStyle = .none
//        return formatter
//    }()
//
//    private static let timeFormatter: DateFormatter = {
//        let formatter = DateFormatter()
//        formatter.dateStyle = .none
//        formatter.timeStyle = .short // e.g., "9:30 AM"
//        return formatter
//    }()
//}
//
//// MARK: - AddVitalReadingSheetView (UPDATED)
//struct AddVitalReadingSheetView: View {
//    @Environment(\.dismiss) var dismiss
//    var onSave: (VitalReading) -> Void
//
//    @State private var selectedType: VitalReading.VitalType = .bp
//    @State private var systolicInput: String = ""
//    @State private var diastolicInput: String = ""
//    @State private var sugarLevelInput: String = ""
//    @State private var selectedDateTime: Date = Date() // Combined for a single DatePicker
//
//    var body: some View {
//        NavigationView {
//            Form {
//                Section(header: Text("Reading Type")) {
//                    Picker("Type", selection: $selectedType) {
//                        ForEach(VitalReading.VitalType.allCases) { type in
//                            Text(type.displayName).tag(type)
//                        }
//                    }
//                    .pickerStyle(.segmented)
//                }
//
//                Section(header: Text("Measurements")) {
//                    if selectedType == .bp {
//                        TextField("Systolic (mmHg)", text: $systolicInput)
//                            .keyboardType(.numberPad)
//                        TextField("Diastolic (mmHg)", text: $diastolicInput)
//                            .keyboardType(.numberPad)
//                    } else {
//                        TextField("Sugar Level (mg/dL)", text: $sugarLevelInput)
//                            .keyboardType(.numberPad)
//                    }
//                }
//
//                Section(header: Text("Date and Time")) {
//                    // Single compact DatePicker for both date and time
//                    DatePicker("Date & Time", selection: $selectedDateTime, displayedComponents: [.date, .hourAndMinute])
//                        .datePickerStyle(.compact) // Use .compact for a small, inline picker
//                }
//            }
//            .navigationTitle("Add Vital Reading")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button("Cancel") {
//                        dismiss()
//                    }
//                }
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button("Add") {
//                        addReading()
//                    }
//                    .disabled(!isValidInput())
//                }
//            }
//        }
//    }
//
//    private func isValidInput() -> Bool {
//        if selectedType == .bp {
//            return !systolicInput.isEmpty && Int(systolicInput) != nil &&
//                   !diastolicInput.isEmpty && Int(diastolicInput) != nil
//        } else {
//            return !sugarLevelInput.isEmpty && Int(sugarLevelInput) != nil
//        }
//    }
//
//    private func addReading() {
//        var newVital: VitalReading
//
//        // Extract date and time components from selectedDateTime for VitalReading
//        let calendar = Calendar.current
//        let dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDateTime)
//        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedDateTime)
//
//        let dateOnly = calendar.date(from: dateComponents) ?? Date()
//        let timeOnly = calendar.date(from: timeComponents) ?? Date()
//
//        if selectedType == .bp {
//            guard let systolic = Int(systolicInput),
//                  let diastolic = Int(diastolicInput) else {
//                print("Invalid BP input")
//                return
//            }
//            newVital = VitalReading(
//                type: .bp,
//                systolic: systolic,
//                diastolic: diastolic,
//                date: dateOnly,
//                time: timeOnly
//            )
//        } else {
//            guard let sugarLevel = Int(sugarLevelInput) else {
//                print("Invalid Sugar input")
//                return
//            }
//            newVital = VitalReading(
//                type: .sugar,
//                sugarLevel: sugarLevel,
//                date: dateOnly,
//                time: timeOnly
//            )
//        }
//        onSave(newVital)
//        dismiss()
//    }
//}
//
//// MARK: - EditVitalReadingSheetView (UPDATED)
//struct EditVitalReadingSheetView: View {
//    @Environment(\.dismiss) var dismiss
//    var vital: VitalReading // The vital reading to edit
//    var onSave: (VitalReading) -> Void
//
//    @State private var selectedType: VitalReading.VitalType
//    @State private var systolicInput: String
//    @State private var diastolicInput: String
//    @State private var sugarLevelInput: String
//    @State private var selectedDateTime: Date // Combined for a single DatePicker
//
//    init(vital: VitalReading, onSave: @escaping (VitalReading) -> Void) {
//        self.vital = vital
//        self.onSave = onSave
//        _selectedType = State(initialValue: vital.type)
//        _systolicInput = State(initialValue: vital.systolic != nil ? String(vital.systolic!) : "")
//        _diastolicInput = State(initialValue: vital.diastolic != nil ? String(vital.diastolic!) : "")
//        _sugarLevelInput = State(initialValue: vital.sugarLevel != nil ? String(vital.sugarLevel!) : "")
//
//        // Combine vital.date and vital.time into a single Date for selectedDateTime
//        let calendar = Calendar.current
//        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: vital.date)
//        let timeComponents = calendar.dateComponents([.hour, .minute], from: vital.time)
//        components.hour = timeComponents.hour
//        components.minute = timeComponents.minute
//        _selectedDateTime = State(initialValue: calendar.date(from: components) ?? Date())
//    }
//
//    var body: some View {
//        NavigationView {
//            Form {
//                Section(header: Text("Reading Type")) {
//                    Picker("Type", selection: $selectedType) {
//                        ForEach(VitalReading.VitalType.allCases) { type in
//                            Text(type.displayName).tag(type)
//                        }
//                    }
//                    .pickerStyle(.segmented)
//                    .disabled(true) // Prevent changing type during edit for simplicity
//                }
//
//                Section(header: Text("Measurements")) {
//                    if selectedType == .bp {
//                        TextField("Systolic (mmHg)", text: $systolicInput)
//                            .keyboardType(.numberPad)
//                        TextField("Diastolic (mmHg)", text: $diastolicInput)
//                            .keyboardType(.numberPad)
//                    } else {
//                        TextField("Sugar Level (mg/dL)", text: $sugarLevelInput)
//                            .keyboardType(.numberPad)
//                    }
//                }
//
//                Section(header: Text("Date and Time")) {
//                    // Single compact DatePicker for both date and time
//                    DatePicker("Date & Time", selection: $selectedDateTime, displayedComponents: [.date, .hourAndMinute])
//                        .datePickerStyle(.compact) // Use .compact for a small, inline picker
//                }
//            }
//            .navigationTitle("Edit Vital Reading")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button("Cancel") {
//                        dismiss()
//                    }
//                }
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button("Save") {
//                        updateReading()
//                    }
//                    .disabled(!isValidInput())
//                }
//            }
//        }
//    }
//
//    private func isValidInput() -> Bool {
//        if selectedType == .bp {
//            return !systolicInput.isEmpty && Int(systolicInput) != nil &&
//                   !diastolicInput.isEmpty && Int(diastolicInput) != nil
//        } else {
//            return !sugarLevelInput.isEmpty && Int(sugarLevelInput) != nil
//        }
//    }
//
//    private func updateReading() {
//        var updatedVital = vital
//
//        // Extract date and time components from selectedDateTime for VitalReading
//        let calendar = Calendar.current
//        let dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDateTime)
//        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedDateTime)
//
//        let dateOnly = calendar.date(from: dateComponents) ?? Date()
//        let timeOnly = calendar.date(from: timeComponents) ?? Date()
//
//
//        if selectedType == .bp {
//            guard let systolic = Int(systolicInput),
//                  let diastolic = Int(diastolicInput) else {
//                print("Invalid BP input")
//                return
//            }
//            updatedVital.systolic = systolic
//            updatedVital.diastolic = diastolic
//            updatedVital.sugarLevel = nil
//        } else {
//            guard let sugarLevel = Int(sugarLevelInput) else {
//                print("Invalid Sugar input")
//                return
//            }
//            updatedVital.sugarLevel = sugarLevel
//            updatedVital.systolic = nil
//            updatedVital.diastolic = nil
//        }
//        updatedVital.date = dateOnly // Update the date
//        updatedVital.time = timeOnly // Update the time
//        onSave(updatedVital)
//        dismiss()
//    }
//}
//
//
//// MARK: - Extension for Date to get time string (OLD - No longer directly used as time is now Date)
//// This extension is not strictly needed anymore if time is stored as Date,
//// but keeping it for reference in case you need custom string formatting elsewhere.
//extension Date {
//    func toLocaleTimeString(timeStyle: DateFormatter.Style = .short) -> String {
//        let formatter = DateFormatter()
//        formatter.timeStyle = timeStyle
//        return formatter.string(from: self)
//    }
//}
//
//
////#Preview {
////    VitalsMonitoringView()
////}
