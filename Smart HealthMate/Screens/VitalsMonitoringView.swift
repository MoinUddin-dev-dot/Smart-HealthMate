//
//  VitalsMonitoringView.swift
//  Smart HealthMate
//
//  Created by Moin on 6/25/25.
//

import SwiftUI

// MARK: - 12. VitalsMonitoringView (NEW VIEW - Drag Gesture Removed)
struct VitalsMonitoringView: View {
    @Binding var isShowingPanelType: PanelType

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Vitals Monitoring")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                }
                Spacer()
                Button(action: {
                    print("Add Reading tapped!")
                    // Action to present a sheet for adding new readings
                }) {
                    Label("Add Reading", systemImage: "plus")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.purple) // Purple background as in image
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding(.bottom, 10)

            // Blood Pressure Card
            VitalsCardView(
                title: "Blood Pressure",
                latestReading: "120/80",
                time: "9:00 AM",
                unit: "mmHg",
                status: "Normal",
                iconName: "heart.fill",
                tintColor: Color.red // Red tint for BP
            )

            // Blood Sugar Card
            VitalsCardView(
                title: "Blood Sugar",
                latestReading: "140",
                time: "8:30 AM",
                unit: "mg/dL",
                status: "Elevated",
                iconName: "waveform.path.ecg.rectangle", // A more fitting sugar icon, though image uses wave
                tintColor: Color.orange // Orange tint for Sugar
            )
            
            Spacer() // Pushes content to the top if there's extra space
        }
        .padding()
        .background(Color.white) // Main panel background
        .cornerRadius(20)
        .shadow(radius: 5)
        // MARK: - Removed: .gesture(DragGesture().onEnded { ... }) to allow parent ScrollView to respond
    }
}

// MARK: - VitalsCardView (Helper View - Fixed "Middle Line")
struct VitalsCardView: View {
    let title: String
    let latestReading: String
    let time: String
    let unit: String
    let status: String
    let iconName: String
    let tintColor: Color

    var body: some View {
        ZStack(alignment: .leading) {
            // 1. Overall Card Background with subtle tint
            RoundedRectangle(cornerRadius: 12)
                .fill(tintColor.opacity(0.05)) // Subtle tint for the entire card background
            
            // 2. Left Border Line
            RoundedRectangle(cornerRadius: 12)
                .fill(tintColor) // Bold tint color for the border
                .frame(width: 4)

            // 3. Main Content VStack (all text, icons - NO SEPARATE WHITE BACKGROUND HERE)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: iconName)
                        .font(.subheadline)
                        .foregroundColor(tintColor)
                        .padding(6)
                        .background(tintColor.opacity(0.15))
                        .clipShape(Circle())

                    VStack(alignment: .leading) {
                        Text(title)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text("Latest Reading")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }

                Text(latestReading)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                HStack {
                    Text(time)
                        .font(.callout)
                        .foregroundColor(.gray)
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(unit)
                            .font(.caption2)
                            .foregroundColor(.gray)
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.up.right")
                                .font(.caption2)
                                .rotationEffect(.degrees(45))
                                .foregroundColor(status == "Normal" ? .green : .orange)
                            Text(status)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(status == "Normal" ? .green : .orange)
                        }
                    }
                }
            }
            .padding(.leading, 15 + 4) // Adjust padding for the border + desired spacing
            .padding(15) // General padding for content inside the card
            // MARK: - REMOVED: .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
            // Now, the VStack will inherit the subtle tint from the overall card background
        }
        .cornerRadius(12) // Overall card corner radius
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
        .padding(.horizontal, 5) // Horizontal spacing from edges
    }
}


// MARK: - VitalReading Struct (NEW)
struct VitalReading: Identifiable, Equatable {
    let id: UUID
    let type: VitalType
    var systolic: Int?
    var diastolic: Int?
    var sugarLevel: Int?
    let date: Date
    let time: String // Store as string to match React example's flexibility

    enum VitalType: String, CaseIterable, Identifiable {
        case bp = "bp"
        case sugar = "sugar"
        var id: String { self.rawValue }
        var displayName: String {
            switch self {
            case .bp: return "Blood Pressure"
            case .sugar: return "Blood Sugar"
            }
        }
    }
    
    init(id: UUID = UUID(), type: VitalType, systolic: Int? = nil, diastolic: Int? = nil, sugarLevel: Int? = nil, date: Date, time: String) {
        self.id = id
        self.type = type
        self.systolic = systolic
        self.diastolic = diastolic
        self.sugarLevel = sugarLevel
        self.date = date
        self.time = time
    }
}

// MARK: - VitalsMonitoringScreen (UPDATED)
struct VitalsMonitoringScreen: View {
    @Binding var vitals: [VitalReading] // Binding to the main vitals state
    let medicinesCount: Int // Added for SMAMedicineTrackerStats
    @State private var showingAddReadingSheet = false

    private var latestBP: VitalReading? {
        vitals.filter { $0.type == .bp }.last
    }

    private var latestSugar: VitalReading? {
        vitals.filter { $0.type == .sugar }.last
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        // Universal Header and Stats
                        Text("Track your blood pressure and sugar levels")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)
                        SMAMedicineTrackerStats(medicinesCount: medicinesCount) // Use the passed count

//                        // Subheading for Vitals - ADDED
//                        VStack(alignment: .leading, spacing: 4) {
//                            Text("Track your blood pressure and sugar levels")
//                                .font(.subheadline)
//                                .foregroundColor(.gray.opacity(0.7))
//                        }
//                        .padding(.horizontal)
//                        .padding(.bottom, 10)

                        // Latest Readings Summary
                        VStack(spacing: 12) { // Changed to VStack for vertical alignment of cards
                            if let latestBP = latestBP {
                                VitalSummaryCard(
                                    type: .bp,
                                    systolic: latestBP.systolic,
                                    diastolic: latestBP.diastolic,
                                    time: latestBP.time
                                )
                            }
                            if let latestSugar = latestSugar {
                                VitalSummaryCard(
                                    type: .sugar,
                                    sugarLevel: latestSugar.sugarLevel,
                                    time: latestSugar.time
                                )
                            }
                            // Placeholder for when no readings exist
                            if latestBP == nil && latestSugar == nil {
                                Text("No vital readings recorded yet. Add your first reading!")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 5)

                        // Recent Readings Section
                        Text("Recent Readings")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.top, 10)
                            .padding(.horizontal)

                        LazyVStack(spacing: 8) {
                            if vitals.isEmpty {
                                Text("No recent vital readings.")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                            } else {
                                ForEach(vitals.suffix(2).reversed()) { vital in // Show last 5, reversed for latest first
                                    RecentVitalReadingRow(vital: vital)
                                }
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 60)
                }
            }
            .navigationTitle("Vitals Monitoring")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddReadingSheet = true
                    }) {
                        Label("Add Reading", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddReadingSheet) {
                AddVitalReadingSheetView { newVital in
                    vitals.append(newVital)
                    // Optional: Sort vitals by date/time if desired
                    vitals.sort { $0.date.compare($1.date) == .orderedAscending }
                }
            }
        }
    }
}

// MARK: - VitalSummaryCard (NEW)
struct VitalSummaryCard: View {
    let type: VitalReading.VitalType
    var systolic: Int?
    var diastolic: Int?
    var sugarLevel: Int?
    let time: String

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [gradientStart, gradientEnd]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(tintColor.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
            .frame(maxWidth: .infinity)
            .aspectRatio(3/1, contentMode: .fit) // Adjusted aspect ratio for a more compact look
            .overlay(
                HStack(alignment: .center) {
                    VStack(alignment: .leading) {
                        Text(displayValue)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(tintColor.opacity(0.8))
                        Text(type.displayName)
                            .font(.subheadline)
                            .foregroundColor(tintColor.opacity(0.6))
                        Text(time)
                            .font(.caption)
                            .foregroundColor(tintColor.opacity(0.5))
                    }
                    Spacer()
                    Image(systemName: iconName)
                        .font(.title2)
                        .padding(8)
                        .background(tintColor.opacity(0.2))
                        .clipShape(Circle())
                        .foregroundColor(tintColor.opacity(0.7))
                }
                .padding(12) // Padding inside the card content
            )
    }

    private var displayValue: String {
        switch type {
        case .bp:
            return "\(systolic ?? 0)/\(diastolic ?? 0)"
        case .sugar:
            return "\(sugarLevel ?? 0)"
        }
    }
    
    private var iconName: String {
        switch type {
        case .bp: return "heart.fill"
        case .sugar: return "waveform.path.ecg" // Changed to waveform for sugar
        }
    }

    private var tintColor: Color {
        switch type {
        case .bp: return .red
        case .sugar: return .orange
        }
    }

    private var gradientStart: Color {
        switch type {
        case .bp: return .red.opacity(0.05)
        case .sugar: return .orange.opacity(0.05)
        }
    }

    private var gradientEnd: Color {
        switch type {
        case .bp: return .red.opacity(0.1)
        case .sugar: return .orange.opacity(0.1)
        }
    }
}

// MARK: - RecentVitalReadingRow (NEW)
struct RecentVitalReadingRow: View {
    let vital: VitalReading

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    var body: some View {
        HStack {
            Image(systemName: vital.type == .bp ? "heart.fill" : "waveform.path.ecg")
                .foregroundColor(vital.type == .bp ? .red : .orange)
                .font(.body)
                .frame(width: 30, height: 30)
                .background(vital.type == .bp ? Color.red.opacity(0.1) : Color.orange.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading) {
                Text(vital.type.displayName)
                    .font(.headline)
                    .fontWeight(.medium)
                Text("\(Self.dateFormatter.string(from: vital.date)) at \(vital.time)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()

            VStack(alignment: .trailing) {
                Text(displayValue)
                    .font(.headline)
                    .fontWeight(.bold)
                Text(vital.type == .bp ? "mmHg" : "mg/dL")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }

    private var displayValue: String {
        switch vital.type {
        case .bp:
            return "\(vital.systolic ?? 0)/\(vital.diastolic ?? 0)"
        case .sugar:
            return "\(vital.sugarLevel ?? 0)"
        }
    }
}

// MARK: - AddVitalReadingSheetView (UPDATED)
struct AddVitalReadingSheetView: View {
    @Environment(\.dismiss) var dismiss
    var onSave: (VitalReading) -> Void

    @State private var selectedType: VitalReading.VitalType = .bp
    @State private var systolicInput: String = ""
    @State private var diastolicInput: String = ""
    @State private var sugarLevelInput: String = ""
    // Corrected to use formatted() directly for specific time format
    @State private var timeInput: String = Date().formatted(date: .omitted, time: .standard)

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Reading Type")) {
                    Picker("Type", selection: $selectedType) {
                        ForEach(VitalReading.VitalType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text("Measurements")) {
                    if selectedType == .bp {
                        TextField("Systolic (mmHg)", text: $systolicInput)
                            .keyboardType(.numberPad)
                        TextField("Diastolic (mmHg)", text: $diastolicInput)
                            .keyboardType(.numberPad)
                    } else {
                        TextField("Sugar Level (mg/dL)", text: $sugarLevelInput)
                            .keyboardType(.numberPad)
                    }
                }

                Section(header: Text("Time")) {
                    TextField("Time (e.g., 9:00 AM)", text: $timeInput)
                }
            }
            .navigationTitle("Add Vital Reading")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addReading()
                    }
                    .disabled(!isValidInput())
                }
            }
        }
    }

    private func isValidInput() -> Bool {
        if selectedType == .bp {
            return !systolicInput.isEmpty && !diastolicInput.isEmpty
        } else {
            return !sugarLevelInput.isEmpty
        }
    }

    private func addReading() {
        var newVital: VitalReading
        // Corrected to use formatted() directly for specific time format
        let currentTime = Date().formatted(date: .omitted, time: .standard)

        if selectedType == .bp {
            guard let systolic = Int(systolicInput),
                  let diastolic = Int(diastolicInput) else {
                // In a real app, you might show a more visible error message
                print("Invalid BP input")
                return
            }
            newVital = VitalReading(
                type: .bp,
                systolic: systolic,
                diastolic: diastolic,
                date: Date(),
                time: timeInput.isEmpty ? currentTime : timeInput
            )
        } else {
            guard let sugarLevel = Int(sugarLevelInput) else {
                print("Invalid Sugar input")
                return
            }
            newVital = VitalReading(
                type: .sugar,
                sugarLevel: sugarLevel,
                date: Date(),
                time: timeInput.isEmpty ? currentTime : timeInput
            )
        }
        onSave(newVital)
        dismiss()
    }
}

// MARK: - Extension for Date to get time string (NEW)
extension Date {
    func toLocaleTimeString(timeStyle: DateFormatter.Style = .short) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = timeStyle
        return formatter.string(from: self)
    }
}


//#Preview {
//    VitalsMonitoringView()
//}
