import SwiftUI

//// MARK: - 13. HealthReportsView (Updated with Monthly Report Option)
//struct HealthReportsView: View {
//    @Binding var isShowingPanelType: PanelType
//    @State private var selectedReportPeriod: String = "Weekly" // Default to Weekly
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 20) {
//            VStack(alignment: .leading, spacing: 5) {
//                Text("Health Reports")
//                    .font(.title2)
//                    .fontWeight(.semibold)
//                Text("Generate and view your health analytics")
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//            }
//            .padding(.bottom, 10)
//
//            HStack(spacing: 10) {
//                ReportPeriodButton(title: "Daily Report", isSelected: selectedReportPeriod == "Daily") {
//                    selectedReportPeriod = "Daily"
//                }
//                ReportPeriodButton(title: "Weekly Report", isSelected: selectedReportPeriod == "Weekly") {
//                    selectedReportPeriod = "Weekly"
//                }
//                ReportPeriodButton(title: "Monthly Report", isSelected: selectedReportPeriod == "Monthly") {
//                    selectedReportPeriod = "Monthly"
//                }
//                Spacer()
//            }
//            .padding(.bottom, 10)
//
//            // Main Report Data Cards (Glassy Effect)
//            ReportDataCardView(
//                value: "85%",
//                description: "This Week's Adherence",
//                iconName: "chart.line.uptrend.xyaxis",
//                tintColor: Color.blue, trend: <#Double?#>
//            )
//            
//            ReportDataCardView(
//                value: "125/82",
//                description: "Avg BP This Week",
//                iconName: "waveform.path",
//                tintColor: Color.green
//            )
//
//            ReportDataCardView(
//                value: "145",
//                description: "Avg Sugar This Week",
//                iconName: "waveform.path",
//                tintColor: Color.orange
//            )
//            
//            // MARK: - Dynamic Report Detail Section
//            // This section will change based on 'selectedReportPeriod'
//            Group {
//                if selectedReportPeriod == "Daily" {
//                    ReportDetailSection( // Display Daily Report
//                        reportType: "Daily Report",
//                        reportDate: "Dec 17, 2024",
//                        adherenceValue: "100%",
//                        bpValue: "120/80",
//                        sugarValue: "140",
//                        showHealthAlerts: false // Daily report image doesn't show alerts
//                    )
//                } else if selectedReportPeriod == "Weekly" {
//                    ReportDetailSection( // Display Weekly Report
//                        reportType: "Weekly Report",
//                        reportDate: "Dec 11-17, 2024",
//                        adherenceValue: "85%",
//                        bpValue: "125/82",
//                        sugarValue: "145",
//                        showHealthAlerts: true // Weekly report image shows alerts
//                    )
//                } else if selectedReportPeriod == "Monthly" {
//                     // MARK: - Monthly Report Details (New)
//                    ReportDetailSection(
//                        reportType: "Monthly Report",
//                        reportDate: "Dec 1-31, 2024", // Example monthly date range
//                        adherenceValue: "92%",       // Example data
//                        bpValue: "128/85",            // Example data
//                        sugarValue: "138",            // Example data
//                        showHealthAlerts: true        // Monthly reports might have alerts
//                    )
//                }
//            }
//            .padding(.top, 10) // Space above this dynamic section
//
//            Spacer()
//        }
//        .padding()
//        .background(Color.white)
//        .cornerRadius(20)
//        .shadow(radius: 5)
//    }
//}

// The following helper views remain unchanged:
//// MARK: - ReportDetailSection (Renamed and Parameterized from GeneratedReportsSection) k
//struct ReportDetailSection: View {
//    let reportType: String
//    let reportDate: String
//    let adherenceValue: String
//    let bpValue: String
//    let sugarValue: String
//    let showHealthAlerts: Bool
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 15) {
//            Text("Generated Reports")
//                .font(.headline)
//                .fontWeight(.semibold)
//                .foregroundColor(.primary)
//            
//            // Individual Report Card Container
//            VStack(alignment: .leading, spacing: 10) {
//                HStack {
//                    Image(systemName: "doc.text")
//                        .font(.title2)
//                        .foregroundColor(.blue)
//                        .padding(8)
//                        .background(Color.blue.opacity(0.15))
//                        .clipShape(Circle())
//                    
//                    VStack(alignment: .leading) {
//                        Text(reportType)
//                            .font(.subheadline)
//                            .fontWeight(.medium)
//                            .foregroundColor(.primary)
//                        Text(reportDate)
//                            .font(.caption)
//                            .foregroundColor(.gray)
//                    }
//                    Spacer()
//                    
//                    Text("12/17/2024") // This date seems static in images, keeping it for now
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                    
//                    Button(action: {
//                        print("PDF Download Tapped for \(reportType)!")
//                    }) {
//                        Label("PDF", systemImage: "arrow.down.doc.fill")
//                            .font(.caption)
//                            .fontWeight(.semibold)
//                            .padding(.vertical, 6)
//                            .padding(.horizontal, 10)
//                            .background(Color.gray.opacity(0.1))
//                            .foregroundColor(.primary)
//                            .cornerRadius(8)
//                    }
//                }
//                
//                // Nested data cards (Simple Tinted Background)
//                SimpleReportDataCardView(value: adherenceValue, description: "Medicine Adherence", iconName: "chart.line.uptrend.xyaxis", tintColor: Color.green)
//                    .padding(.horizontal, 0)
//                SimpleReportDataCardView(value: bpValue, description: "Avg Blood Pressure", iconName: "waveform.path", tintColor: Color.green)
//                    .padding(.horizontal, 0)
//                SimpleReportDataCardView(value: sugarValue, description: "Avg Blood Sugar", iconName: "waveform.path", tintColor: Color.green)
//                    .padding(.horizontal, 0)
//
//            }
//            .padding(15)
//            .background(Color.white)
//            .cornerRadius(12)
//            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
//            .padding(.horizontal, 5)
//
//            // Health Alerts Section (Conditional Display)
//            if showHealthAlerts {
//                Text("Health Alerts")
//                    .font(.headline)
//                    .fontWeight(.semibold)
//                    .foregroundColor(.primary)
//                    .padding(.top, 5)
//                
//                HealthAlertRow(
//                    message: "BP slightly elevated on 3 occasions",
//                    tintColor: Color.orange.opacity(0.15)
//                )
//                HealthAlertRow(
//                    message: "Missed Metformin on Monday",
//                    tintColor: Color.orange.opacity(0.15)
//                )
//            }
//        }
//    }
//}

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

//// MARK: - ReportDataCardView (Helper View - Glassy/Gradient Effect Applied)
//struct ReportDataCardView: View {
//    let value: String
//    let description: String
//    let iconName: String
//    let tintColor: Color
//
//    var body: some View {
//        HStack {
//            VStack(alignment: .leading, spacing: 4) {
//                Text(value)
//                    .font(.title)
//                    .fontWeight(.bold)
//                    .foregroundColor(tintColor.opacity(0.8))
//                Text(description)
//                    .font(.subheadline)
//                    .foregroundColor(tintColor.opacity(0.6))
//            }
//            .padding(.leading, 15)
//            .padding(.vertical, 15)
//
//            Spacer()
//
//            Image(systemName: iconName)
//                .font(.title2)
//                .foregroundColor(tintColor.opacity(0.8))
//                .padding(8)
//                .background(tintColor.opacity(0.15))
//                .clipShape(Circle())
//                .padding(.trailing, 15)
//        }
//        .padding(.horizontal, 0)
//        .background(
//            RoundedRectangle(cornerRadius: 12)
//                .fill(
//                    LinearGradient(
//                        gradient: Gradient(colors: [tintColor.opacity(0.2), tintColor.opacity(0.05)]),
//                        startPoint: .topLeading,
//                        endPoint: .bottomTrailing
//                    )
//                )
//                .background(.ultraThinMaterial)
//        )
//        .cornerRadius(12)
//        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
//        .padding(.horizontal, 5)
//        .padding(.vertical, 4)
//    }
//}

//// MARK: - SimpleReportDataCardView (Helper View for nested cards - Solid Tinted Background)
//struct SimpleReportDataCardView: View {
//    let value: String
//    let description: String
//    let iconName: String
//    let tintColor: Color
//
//    var body: some View {
//        HStack {
//            Image(systemName: iconName)
//                .font(.body)
//                .foregroundColor(tintColor)
//            
//            Text(value)
//                .font(.title2)
//                .fontWeight(.bold)
//                .foregroundColor(tintColor)
//            
//            Spacer()
//            
//            Text(description)
//                .font(.subheadline)
//                .foregroundColor(.gray)
//        }
//        .padding(12)
//        .background(
//            RoundedRectangle(cornerRadius: 8)
//                .fill(tintColor.opacity(0.1))
//        )
//        .cornerRadius(8)
//    }
//}

//// MARK: - HealthAlertRow (Helper View for individual health alerts)
//struct HealthAlertRow: View {
//    let message: String
//    let tintColor: Color
//
//    var body: some View {
//        HStack(alignment: .top, spacing: 10) {
//            Image(systemName: "exclamationmark.triangle.fill")
//                .font(.subheadline)
//                .foregroundColor(.orange)
//                .padding(.top, 2)
//            
//            Text(message)
//                .font(.subheadline)
//                .foregroundColor(.primary)
//            
//            Spacer()
//        }
//        .padding(12)
//        .background(tintColor)
//        .cornerRadius(8)
//        .padding(.horizontal, 5)
//    }
//}



// MARK: - 13. HealthReportsScreen (Updated with Monthly Report Option)
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
                                    reportDate: "Dec 17, 2024",
                                    adherenceValue: "100%",
                                    bpValue: "120/80",
                                    sugarValue: "140",
                                    showHealthAlerts: false // Daily report image doesn't show alerts
                                )
                            } else if selectedReportPeriod == "Weekly" {
                                ReportDetailSection( // Display Weekly Report
                                    reportType: "Weekly Report",
                                    reportDate: "Dec 11-17, 2024",
                                    adherenceValue: "85%",
                                    bpValue: "125/82",
                                    sugarValue: "145",
                                    showHealthAlerts: true // Weekly report image shows alerts
                                )
                            } else if selectedReportPeriod == "Monthly" {
                                // MARK: - Monthly Report Details (New)
                                ReportDetailSection(
                                    reportType: "Monthly Report",
                                    reportDate: "Dec 1-31, 2024", // Example monthly date range
                                    adherenceValue: "92%",       // Example data
                                    bpValue: "128/85",            // Example data
                                    sugarValue: "138",            // Example data
                                    showHealthAlerts: true        // Monthly reports might have alerts
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
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                // Move Daily/Weekly/Monthly buttons to the toolbar using a segmented picker
                ToolbarItem(placement: .principal) {
                    Picker("Report Period", selection: $selectedReportPeriod) {
                        Text("Daily").tag("Daily")
                        Text("Weekly").tag("Weekly")
                        Text("Monthly").tag("Monthly")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 250) // Adjust width as needed for better layout
                }
            }
        }
    }
}


// The following helper views remain unchanged:
// MARK: - ReportDetailSection (Renamed and Parameterized from GeneratedReportsSection)
struct ReportDetailSection: View {
    let reportType: String
    let reportDate: String
    let adherenceValue: String
    let bpValue: String
    let sugarValue: String
    let showHealthAlerts: Bool

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
                    
                    Text("12/17/2024") // This date seems static in images, keeping it for now
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
                SimpleReportDataCardView(value: adherenceValue, description: "Medicine Adherence", iconName: "chart.line.uptrend.xyaxis", tintColor: Color.green, trend: nil) // No specific trend for these sub-cards in this context
                SimpleReportDataCardView(value: bpValue, description: "Avg Blood Pressure", iconName: "waveform.path", tintColor: Color.green, trend: nil)
                SimpleReportDataCardView(value: sugarValue, description: "Avg Blood Sugar", iconName: "waveform.path", tintColor: Color.green, trend: nil)

            }
            .padding(15)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
            .padding(.horizontal, 5)

            // Health Alerts Section (Conditional Display)
            if showHealthAlerts {
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

// MARK: - HealthAlertRow (Helper View for individual health alerts)
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
