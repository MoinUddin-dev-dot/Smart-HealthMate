import SwiftUI

// MARK: - ReportPeriodButton (Helper View for Daily/Weekly/Monthly buttons)
struct ReportPeriodButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue.opacity(0.15) : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .blue : .gray)
                .cornerRadius(8)
        }
    }
}

// MARK: - SMAMedicineTrackerHeader (Dummy, as it's used but not provided)
// You should have this struct defined elsewhere in your project.
// Adding a basic dummy for compilation.
//struct SMAMedicineTrackerHeader: View {
//    var body: some View {
//        HStack {
//            Text("Smart HealthMate")
//                .font(.title2)
//                .fontWeight(.bold)
//            Spacer()
//            // Add other header elements if needed
//        }
//        .padding(.horizontal)
//    }
//}
//
//// MARK: - SMAMedicineTrackerStats (Dummy, as it's used but not provided)
//// You should have this struct defined elsewhere in your project.
//// Adding a basic dummy for compilation.
//struct SMAMedicineTrackerStats: View {
//    let medicinesCount: Int
//
//    var body: some View {
//        HStack {
//            Spacer()
//            VStack {
//                Text("\(medicinesCount)")
//                    .font(.title)
//                    .fontWeight(.bold)
//                Text("Medicines Tracked")
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//            }
//            Spacer()
//        }
//        .padding()
//        .background(Color.blue.opacity(0.1))
//        .cornerRadius(12)
//        .padding(.horizontal)
//    }
//}


// MARK: - 13. HealthReportsScreen (Updated with Monthly Report Option and new layout)
struct HealthReportsScreen: View {
    let medicinesCount: Int // Retained for consistency with SMAMedicineTrackerStats
    @State private var selectedReportPeriod: String = "Weekly" // Default to Weekly

    var body: some View {
        NavigationStack { // Each screen has its own NavigationStack
            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        SMAMedicineTrackerHeader()
                        SMAMedicineTrackerStats(medicinesCount: medicinesCount)

                        // Subheading for Health Reports
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Generate and view your health analytics")
                                .font(.subheadline)
                                .foregroundColor(.gray.opacity(0.7))
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 10)

                        // MARK: - Moved Daily/Weekly/Monthly buttons here
                        HStack(spacing: 10) {
                            ReportPeriodButton(title: "Daily", isSelected: selectedReportPeriod == "Daily") {
                                selectedReportPeriod = "Daily"
                            }
                            ReportPeriodButton(title: "Weekly", isSelected: selectedReportPeriod == "Weekly") {
                                selectedReportPeriod = "Weekly"
                            }
                            ReportPeriodButton(title: "Monthly", isSelected: selectedReportPeriod == "Monthly") {
                                selectedReportPeriod = "Monthly"
                            }
                        }
                        .padding(.horizontal) // Apply padding to the HStack containing buttons
                        .padding(.bottom, 10) // Space between buttons and cards

                        // Main Report Data Cards (Glassy Effect)
                        ReportDataCardView(
                            value: "85%",
                            description: "This Week's Adherence",
                            iconName: "chart.line.uptrend.xyaxis",
                            tintColor: Color.blue,
                            trend: -5.0 // Example: indicating a slight drop in adherence
                        )
                        .padding(.horizontal,10)

                        ReportDataCardView(
                            value: "125/82",
                            description: "Avg BP This Week",
                            iconName: "waveform.path",
                            tintColor: Color.green,
                            trend: 2.0 // Example: indicating a slight increase in BP (though still normal)
                        )
                        .padding(.horizontal,10)

                        ReportDataCardView(
                            value: "145",
                            description: "Avg Sugar This Week",
                            iconName: "waveform.path",
                            tintColor: Color.orange,
                            trend: -3.0 // Example: indicating a slight drop in sugar
                        )
                        .padding(.horizontal,10)

                        // MARK: - Dynamic Report Detail Section
                        // This section will change based on 'selectedReportPeriod'
                        Group {
                            if selectedReportPeriod == "Daily" {
                                ReportDetailSection( // Display Daily Report
                                    reportType: "Daily Report",
                                    reportDate: "July 3, 2025", // Updated to current date
                                    adherenceValue: "100%",
                                    bpValue: "120/80",
                                    sugarValue: "140",
                                    showHealthAlerts: false // Daily report image doesn't show alerts
                                )
                            } else if selectedReportPeriod == "Weekly" {
                                ReportDetailSection( // Display Weekly Report
                                    reportType: "Weekly Report",
                                    reportDate: "June 27 - July 3, 2025", // Updated to current week
                                    adherenceValue: "85%",
                                    bpValue: "125/82",
                                    sugarValue: "145",
                                    showHealthAlerts: false // Health Alerts section removed, so always false
                                )
                            } else if selectedReportPeriod == "Monthly" {
                                // MARK: - Monthly Report Details (New)
                                ReportDetailSection(
                                    reportType: "Monthly Report",
                                    reportDate: "June 1 - June 30, 2025", // Updated to previous month
                                    adherenceValue: "92%",
                                    bpValue: "128/85",
                                    sugarValue: "138",
                                    showHealthAlerts: false // Health Alerts section removed, so always false
                                )
                            }
                        }
                        .padding(.top, 10) // Space above this dynamic section

                        Spacer()
                    }
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 60) // Ensure space for bottom bar
                }
            }
            .navigationTitle("Health Reports")
            // MARK: - Navigation Title Display Mode Changed
//            .navigationBarTitleDisplayMode(.inline) // This makes it inline by default
            // To make it large when not scrolled and inline when scrolled, you'd typically need a custom scroll detection.
            // For standard behavior, .inline makes it compact, .large makes it large by default.
            // If you want a dynamic effect, you'd usually use a @State variable tied to scroll position,
            // but for simple requirement "display inline hojaye", .inline is the direct answer.
            // If you meant large initially and then inline on scroll, that's `.automatic` or requires manual state management.
            // Let's stick to .inline for now as it makes it "inline hojaye".

            .toolbar {
                // Removed the Picker from toolbar as per new requirement
            }
        }
    }
}


// The following helper views remain unchanged, but I'll include them for completeness.
// MARK: - ReportDetailSection (Renamed and Parameterized from GeneratedReportsSection)
struct ReportDetailSection: View {
    let reportType: String
    let reportDate: String
    let adherenceValue: String
    let bpValue: String
    let sugarValue: String
    let showHealthAlerts: Bool // This parameter will now effectively always be `false`

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Generated Reports")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            // Individual Report Card Container
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "doc.text")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .padding(8)
                        .background(Color.blue.opacity(0.15))
                        .clipShape(Circle())

                    VStack(alignment: .leading) {
                        Text(reportType)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        Text(reportDate)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()

                    // This date seems static in images, keeping it for now, but consider making it dynamic
                    Text("12/17/2024") // This is still a static date in the image, consider making it dynamic based on reportDate
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button(action: {
                        print("PDF Download Tapped for \(reportType)!")
                    }) {
                        Label("PDF", systemImage: "arrow.down.doc.fill")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(Color.gray.opacity(0.1))
                            .foregroundColor(.primary)
                            .cornerRadius(8)
                    }
                }

                // Nested data cards (Simple Tinted Background)
                SimpleReportDataCardView(value: adherenceValue, description: "Medicine Adherence", iconName: "chart.line.uptrend.xyaxis", tintColor: Color.green, trend: nil)
                SimpleReportDataCardView(value: bpValue, description: "Avg Blood Pressure", iconName: "waveform.path", tintColor: Color.green, trend: nil)
                SimpleReportDataCardView(value: sugarValue, description: "Avg Blood Sugar", iconName: "waveform.path", tintColor: Color.green, trend: nil)

            }
            .padding(15)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
            .padding(.horizontal, 5)

            // MARK: - Health Alerts Section (REMOVED as per requirement)
            /*
            if showHealthAlerts { // This `if` block will never execute now
                Text("Health Alerts")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .padding(.top, 5)

                HealthAlertRow(
                    message: "BP slightly elevated on 3 occasions",
                    tintColor: Color.orange.opacity(0.15)
                )
                HealthAlertRow(
                    message: "Missed Metformin on Monday",
                    tintColor: Color.orange.opacity(0.15)
                )
            }
            */
        }
    }
}

// MARK: - ReportDataCardView (Helper View - Glassy/Gradient Effect Applied)
struct ReportDataCardView: View {
    let value: String
    let description: String
    let iconName: String
    let tintColor: Color
    let trend: Double? // Positive for up, negative for down, nil/zero for neutral

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(tintColor.opacity(0.8))
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(tintColor.opacity(0.6))
            }
            .padding(.leading, 15)
            .padding(.vertical, 15)

            Spacer()

            if let trend = trend {
                HStack(spacing: 4) {
                    Image(systemName: trend > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .font(.subheadline)
                        .foregroundColor(trend > 0 ? .green : .red)
                    Text(String(format: "%.1f%%", abs(trend)))
                        .font(.caption)
                        .foregroundColor(trend > 0 ? .green : .red)
                }
                .padding(.trailing, 8)
            }

            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(tintColor.opacity(0.8))
                .padding(8)
                .background(tintColor.opacity(0.15))
                .clipShape(Circle())
                .padding(.trailing, 15)
        }
        .padding(.horizontal, 0)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [tintColor.opacity(0.2), tintColor.opacity(0.05)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(.ultraThinMaterial)
        )
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
        .padding(.horizontal, 5)
        .padding(.vertical, 4)
    }
}

// MARK: - SimpleReportDataCardView (Helper View for nested cards - Solid Tinted Background)
struct SimpleReportDataCardView: View {
    let value: String
    let description: String
    let iconName: String
    let tintColor: Color
    let trend: Double? // Positive for up, negative for down, nil/zero for neutral

    var body: some View {
        HStack {
            Image(systemName: iconName)
                .font(.body)
                .foregroundColor(tintColor)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(tintColor)

            Spacer()

            if let trend = trend {
                HStack(spacing: 4) {
                    Image(systemName: trend > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .font(.caption)
                        .foregroundColor(trend > 0 ? .green : .red)
                    Text(String(format: "%.1f%%", abs(trend)))
                        .font(.caption2)
                        .foregroundColor(trend > 0 ? .green : .red)
                }
                .padding(.trailing, 4)
            }

            Text(description)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(tintColor.opacity(0.1))
        )
        .cornerRadius(8)
    }
}

// MARK: - HealthAlertRow (Helper View for individual health alerts - RETAINED but not used directly in HealthReportsScreen)
// This struct is kept in case you use it elsewhere, but it's no longer part of HealthReportsScreen.
struct HealthAlertRow: View {
    let message: String
    let tintColor: Color

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.subheadline)
                .foregroundColor(.orange)
                .padding(.top, 2)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(12)
        .background(tintColor)
        .cornerRadius(8)
        .padding(.horizontal, 5)
    }
}
