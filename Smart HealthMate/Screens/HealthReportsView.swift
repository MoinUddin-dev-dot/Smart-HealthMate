import SwiftUI
import SwiftData
import Charts
import PDFKit

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

// MARK: - AdherenceChartView (Bar Chart for Daily Medicine Adherence, Line Chart for Weekly/Monthly)
struct AdherenceChartView: View {
    let medicines: [Medicine]
    let period: String
    let userSettings: UserSettings?

    // Updated struct to hold daily adherence percentage
    private struct AdherenceData: Identifiable {
        let id = UUID()
        let date: Date
        let adherencePercentage: Double // 0.0 to 100.0
        let medicineName: String // For annotations
    }

    private func prepareAdherenceData() -> [AdherenceData] {
        guard let userSettings = userSettings, !medicines.isEmpty else { return [] }
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date
        let days: Int

        // Set date range based on period
        switch period {
        case "Daily":
            startDate = calendar.startOfDay(for: now)
            days = 1
        case "Weekly":
            startDate = calendar.date(byAdding: .day, value: -6, to: now) ?? now
            days = 7
        case "Monthly":
            startDate = calendar.date(byAdding: .day, value: -29, to: now) ?? now
            days = 30
        default:
            startDate = now
            days = 1
        }

        var data: [AdherenceData] = []

        if period == "Daily" {
            // Existing logic for Daily: Bar chart for individual doses
            for medicine in medicines {
                guard let scheduledDoses = medicine.scheduledDoses, let doseLogEvents = medicine.doseLogEvents else { continue }
                for dose in scheduledDoses {
                    let components = calendar.dateComponents([.hour, .minute], from: dose.time)
                    guard let doseTimeToday = calendar.date(bySettingHour: components.hour!,
                                                            minute: components.minute!,
                                                            second: 0,
                                                            of: now) else { continue }
                    if doseTimeToday >= startDate && doseTimeToday <= now {
                        let event = doseLogEvents.first { event in
                            event.scheduledDose?.id == dose.id &&
                            calendar.isDate(event.dateRecorded, inSameDayAs: startDate)
                        }
                        data.append(AdherenceData(
                            date: doseTimeToday,
                            adherencePercentage: event?.isTaken ?? false ? 100.0 : 0.0,
                            medicineName: medicine.name
                        ))
                    }
                }
            }
        } else {
            // Logic for Weekly/Monthly: Calculate daily adherence percentage
            let dateRange = stride(from: 0, to: days, by: 1).map { offset in
                calendar.date(byAdding: .day, value: offset, to: startDate)!
            }

            for date in dateRange {
                let dayStart = calendar.startOfDay(for: date)
                var totalDosesDue = 0
                var totalDosesTaken = 0

                for medicine in medicines {
                    guard let scheduledDoses = medicine.scheduledDoses, let doseLogEvents = medicine.doseLogEvents else { continue }

                    // Count doses due on this day
                    let dosesDue = scheduledDoses.filter { dose in
                        let components = calendar.dateComponents([.hour, .minute], from: dose.time)
                        guard let doseTimeOnDay = calendar.date(bySettingHour: components.hour!,
                                                               minute: components.minute!,
                                                               second: 0,
                                                               of: date) else { return false }
                        return doseTimeOnDay <= now
                    }
                    totalDosesDue += dosesDue.count

                    // Count doses taken on this day
                    for dose in dosesDue {
                        let takenEvent = doseLogEvents.first { event in
                            event.scheduledDose?.id == dose.id &&
                            calendar.isDate(event.dateRecorded, inSameDayAs: dayStart) &&
                            event.isTaken
                        }
                        if takenEvent != nil {
                            totalDosesTaken += 1
                        }
                    }
                }

                // Calculate adherence percentage for the day
                let adherencePercentage = totalDosesDue > 0 ? (Double(totalDosesTaken) / Double(totalDosesDue) * 100.0) : 0.0
                data.append(AdherenceData(
                    date: dayStart,
                    adherencePercentage: adherencePercentage,
                    medicineName: "Daily Average"
                ))
            }
        }

        return data.sorted { $0.date < $1.date }
    }

    var body: some View {
        let data = prepareAdherenceData()

        Chart {
            ForEach(data) { entry in
                if period == "Daily" {
                    // BarMark for Daily
                    BarMark(
                        x: .value("Time", entry.date, unit: .hour),
                        y: .value("Status", entry.adherencePercentage == 100.0 ? 1.0 : 0.1)
                    )
                    .foregroundStyle(entry.adherencePercentage == 100.0 ? Color.green : Color.red)
                    .annotation(position: .top) {
                        Text(entry.medicineName)
                            .font(.caption2)
                            .foregroundColor(.primary)
                    }
                } else {
                    // LineMark for Weekly/Monthly
                    LineMark(
                        x: .value("Date", entry.date, unit: .day),
                        y: .value("Adherence %", entry.adherencePercentage)
                    )
                    .foregroundStyle(Color.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .symbol(Circle().strokeBorder(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                    .annotation(position: .top) {
                        Text(String(format: "%.0f%%", entry.adherencePercentage))
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .chartXAxis {
            if period == "Daily" {
                AxisMarks(values: stride(from: 0, through: 23, by: 3).map { hour in
                    Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
                }) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .abbreviated)))
                }
            } else if period == "Weekly" {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.day().month())
                }
            } else {
                // Monthly: Show labels at 0, -5, -10, ..., -30 (from today to 30 days ago)
                AxisMarks(values: stride(from: 0, to: -30, by: -5).map { offset in
                    Calendar.current.date(byAdding: .day, value: offset, to: Date())!
                }) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            let daysAgo = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
                            Text("\(daysAgo) Days ")
                        }
                    }
                }
            }
        }
        .chartXScale(
            domain: {
                let calendar = Calendar.current
                let now = Date()
                if period == "Daily" {
                    let start = calendar.startOfDay(for: now)
                    let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now)!
                    return start...end
                } else {
                    let days = period == "Weekly" ? -6 : -29
                    let start = calendar.date(byAdding: .day, value: days, to: now)!
                    return start...now
                }
            }()
        )
        .chartYScale(domain: period == "Daily" ? 0.0...1.1 : 0.0...100.0)
        .chartYAxis {
            if period == "Daily" {
                AxisMarks(values: [0.1, 1.0]) { value in
                    AxisGridLine()
                        .foregroundStyle(.gray)
                    AxisValueLabel {
                        if let doubleVal = value.as(Double.self) {
                            Text(doubleVal == 1.0 ? "Taken" : "Missed")
                                .font(.caption)
                                .offset(y: doubleVal == 0.1 ? -8 : 0)
                        }
                    }
                }
            } else {
                AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                    AxisGridLine()
                        .foregroundStyle(.gray)
                    AxisValueLabel {
                        if let doubleVal = value.as(Double.self) {
                            Text("\(Int(doubleVal))%")
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .frame(height: 240)
        .chartLegend {
            legendView
        }
    }

    private var legendView: some View {
        HStack(spacing: 12) {
            if period == "Daily" {
                Label("Taken", systemImage: "circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                Label("Missed", systemImage: "circle.fill")
                    .foregroundColor(.red)
                    .font(.caption)
            } else {
                Label("Adherence", systemImage: "circle.fill")
                    .foregroundColor(.blue)
                    .font(.caption)
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - BPChartView (Line Chart for Blood Pressure)
import SwiftUI
import Charts
// MARK: - BPChartView (Area Chart for Blood Pressure)
// MARK: - BPChartView (Area Chart for Blood Pressure)
import SwiftUI
import Charts

struct BPChartView: View {
    let vitalReadings: [VitalReading]
    let period: String
    let bpThreshold: SMABPThreshold?

    private struct BPData: Identifiable {
        let id = UUID()
        let timestamp: Date
        let value: Int
        let type: BPType
        let isOutOfRange: Bool

        enum BPType: String, CaseIterable {
            case systolic = "Systolic"
            case diastolic = "Diastolic"
        }
    }

    private func prepareBPData() -> [BPData] {
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date = {
            switch period {
            case "Daily": return calendar.startOfDay(for: now)
            case "Weekly": return calendar.date(byAdding: .day, value: -6, to: now) ?? now
            case "Monthly": return calendar.date(byAdding: .day, value: -29, to: now) ?? now
            default: return now
            }
        }()

        var bpData: [BPData] = []
        let bpReadings = vitalReadings.filter { $0.type == .bp && $0.date >= startDate && $0.date <= now }

        if period == "Daily" {
            for reading in bpReadings {
                let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: reading.time)
                let baseTimestamp = calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                                  minute: timeComponents.minute ?? 0,
                                                  second: timeComponents.second ?? 0,
                                                  of: reading.date) ?? reading.date

                if let systolic = reading.systolic {
                    let isOutOfRange = bpThreshold != nil &&
                        (systolic < bpThreshold!.minSystolic || systolic > bpThreshold!.maxSystolic)
                    let systolicTimestamp = calendar.date(byAdding: .minute, value: -1, to: baseTimestamp) ?? baseTimestamp
                    bpData.append(BPData(timestamp: systolicTimestamp, value: systolic, type: .systolic, isOutOfRange: isOutOfRange))
                }

                if let diastolic = reading.diastolic {
                    let isOutOfRange = bpThreshold != nil &&
                        (diastolic < bpThreshold!.minDiastolic || diastolic > bpThreshold!.maxDiastolic)
                    let diastolicTimestamp = calendar.date(byAdding: .minute, value: 1, to: baseTimestamp) ?? baseTimestamp
                    bpData.append(BPData(timestamp: diastolicTimestamp, value: diastolic, type: .diastolic, isOutOfRange: isOutOfRange))
                }
            }
        } else {
            let days = period == "Weekly" ? 7 : 30
            let dateRange = stride(from: 0, to: days, by: 1).map {
                calendar.date(byAdding: .day, value: $0, to: startDate)!
            }

            for date in dateRange {
                let dayStart = calendar.startOfDay(for: date)
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
                let dayReadings = bpReadings.filter { $0.date >= dayStart && $0.date < dayEnd }

                let systolicValues = dayReadings.compactMap { $0.systolic }
                let diastolicValues = dayReadings.compactMap { $0.diastolic }

                if !systolicValues.isEmpty {
                    let avgSystolic = systolicValues.reduce(0, +) / systolicValues.count
                    let isOutOfRange = bpThreshold != nil &&
                        (avgSystolic < bpThreshold!.minSystolic || avgSystolic > bpThreshold!.maxSystolic)
                    bpData.append(BPData(timestamp: dayStart, value: avgSystolic, type: .systolic, isOutOfRange: isOutOfRange))
                }

                if !diastolicValues.isEmpty {
                    let avgDiastolic = diastolicValues.reduce(0, +) / diastolicValues.count
                    let isOutOfRange = bpThreshold != nil &&
                        (avgDiastolic < bpThreshold!.minDiastolic || avgDiastolic > bpThreshold!.maxDiastolic)
                    bpData.append(BPData(timestamp: dayStart, value: avgDiastolic, type: .diastolic, isOutOfRange: isOutOfRange))
                }
            }
        }

        return bpData.sorted { $0.timestamp < $1.timestamp }
    }

    private func getYRange(for data: [BPData]) -> ClosedRange<Double> {
        let maxValue = data.map { $0.value }.max() ?? 0
        return 0...(maxValue > 150 ? Double(((maxValue + 9) / 10) * 10) : 200)
    }

    private var legendView: some View {
        HStack(spacing: 16) {
            Label("Systolic", systemImage: "square.fill")
                .foregroundColor(.blue)
                .font(.caption)
            Label("Diastolic", systemImage: "square.fill")
                .foregroundColor(.green)
                .font(.caption)
//            Label("Out of Range", systemImage: "square.fill")
//                .foregroundColor(.red)
//                .font(.caption)
        }
        .padding(.top, 8)
    }

    var body: some View {
        let data = prepareBPData()
        let calendar = Calendar.current
        let now = Date()
        let startDate = period == "Daily" ? calendar.startOfDay(for: now) :
                         period == "Weekly" ? calendar.date(byAdding: .day, value: -6, to: now) ?? now :
                         calendar.date(byAdding: .day, value: -29, to: now) ?? now

        VStack(alignment: .leading) {
            if data.isEmpty {
                Text("No BP readings available for \(period.lowercased()) period")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            } else {
                Chart {
                    // Draw Data Lines
                    ForEach(data) { reading in
                        LineMark(
                            x: .value("Time", reading.timestamp),
                            y: .value("Value", reading.value),
                            series: .value("Type",  reading.type.rawValue)
                        )
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .symbol(Circle().strokeBorder(lineWidth: 2))
                        .foregroundStyle(by: .value("Type",  reading.type.rawValue))
                    }

                    // Threshold Lines
                    if let threshold = bpThreshold {
                        RuleMark(y: .value("Systolic Max", threshold.maxSystolic))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                            .foregroundStyle(Color.red.opacity(0.3))

                        RuleMark(y: .value("Systolic Min", threshold.minSystolic))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                            .foregroundStyle(Color.red.opacity(0.3))

                        RuleMark(y: .value("Diastolic Max", threshold.maxDiastolic))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                            .foregroundStyle(Color.purple.opacity(0.9))

                        RuleMark(y: .value("Diastolic Min", threshold.minDiastolic))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                            .foregroundStyle(Color.purple.opacity(0.9))
                    }
                }
                .chartForegroundStyleScale([
                    "Systolic": .blue,
                    "Diastolic": .green,
                    "Out of Range": .red
                ])
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartYScale(domain: getYRange(for: data))
                .chartXAxis {
                    if period == "Daily" {
                        AxisMarks(
                            values: stride(from: 0, through: 23, by: 3).compactMap {
                                calendar.date(bySettingHour: $0, minute: 0, second: 0, of: startDate)
                            }
                        ) { value in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .abbreviated)))
                        }
                    } else if period == "Monthly" {
                        AxisMarks(
                            values: stride(from: 0, through: 29, by: 5).map {
                                calendar.date(byAdding: .day, value: -$0, to: now)!
                            }
                        ) { value in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.day().month())
                        }
                    } else {
                        AxisMarks(values: .stride(by: .day)) {
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.day().month())
                        }
                    }
                }
                .chartXScale(domain: {
                    if period == "Daily" {
                        let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now)!
                        return startDate...end
                    } else {
                        return startDate...now
                    }
                }())
                .frame(height: 220)
            }

            legendView
        }
    }
}


// MARK: - SugarChartView (Area Chart for Blood Sugar)
import SwiftUI
import Charts

struct SugarChartView: View {
    let vitalReadings: [VitalReading]
    let period: String
    let fastingThreshold: SMASugarThreshold?
    let afterMealThreshold: SMASugarThreshold?

    private struct SugarData: Identifiable {
        let id = UUID()
        let timestamp: Date
        let value: Int
        let type: VitalReading.SugarReadingType
        let isOutOfRange: Bool
    }

    private func prepareSugarData() -> [SugarData] {
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date
        switch period {
        case "Daily":
            startDate = calendar.startOfDay(for: now)
        case "Weekly":
            startDate = calendar.date(byAdding: .day, value: -6, to: now) ?? now
        case "Monthly":
            startDate = calendar.date(byAdding: .day, value: -29, to: now) ?? now
        default:
            startDate = now
        }

        var sugarData: [SugarData] = []
        let sugarReadings = vitalReadings.filter { $0.type == .sugar && $0.date >= startDate && $0.date <= now }

        if period == "Daily" {
            for reading in sugarReadings {
                let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: reading.time)
                let baseTimestamp = calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                                 minute: timeComponents.minute ?? 0,
                                                 second: timeComponents.second ?? 0,
                                                 of: reading.date) ?? reading.date

                if let sugarLevel = reading.sugarLevel, let sugarType = reading.sugarReadingType {
                    let isOutOfRange: Bool
                    if sugarType == .fasting {
                        isOutOfRange = fastingThreshold != nil && (sugarLevel < fastingThreshold!.min || sugarLevel > fastingThreshold!.max)
                        let fastingTimestamp = calendar.date(byAdding: .minute, value: -5, to: baseTimestamp) ?? baseTimestamp
                        sugarData.append(SugarData(timestamp: fastingTimestamp, value: sugarLevel, type: sugarType, isOutOfRange: isOutOfRange))
                    } else {
                        isOutOfRange = afterMealThreshold != nil && (sugarLevel < afterMealThreshold!.min || sugarLevel > afterMealThreshold!.max)
                        let afterMealTimestamp = calendar.date(byAdding: .minute, value: 5, to: baseTimestamp) ?? baseTimestamp
                        sugarData.append(SugarData(timestamp: afterMealTimestamp, value: sugarLevel, type: sugarType, isOutOfRange: isOutOfRange))
                    }
                }
            }
        } else {
            let days = period == "Weekly" ? 7 : 30
            let dateRange = stride(from: 0, to: days, by: 1).map {
                calendar.date(byAdding: .day, value: $0, to: startDate)!
            }

            for date in dateRange {
                let dayStart = calendar.startOfDay(for: date)
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
                let dayReadings = sugarReadings.filter { $0.date >= dayStart && $0.date < dayEnd }

                let fastingValues = dayReadings.filter { $0.sugarReadingType == .fasting }.compactMap { $0.sugarLevel }
                let afterMealValues = dayReadings.filter { $0.sugarReadingType == .afterMeal }.compactMap { $0.sugarLevel }

                if !fastingValues.isEmpty {
                    let avgFasting = fastingValues.reduce(0, +) / fastingValues.count
                    let isOutOfRange = fastingThreshold != nil && (avgFasting < fastingThreshold!.min || avgFasting > fastingThreshold!.max)
                    sugarData.append(SugarData(timestamp: dayStart, value: avgFasting, type: .fasting, isOutOfRange: isOutOfRange))
                }

                if !afterMealValues.isEmpty {
                    let avgAfterMeal = afterMealValues.reduce(0, +) / afterMealValues.count
                    let isOutOfRange = afterMealThreshold != nil && (avgAfterMeal < afterMealThreshold!.min || avgAfterMeal > afterMealThreshold!.max)
                    sugarData.append(SugarData(timestamp: dayStart, value: avgAfterMeal, type: .afterMeal, isOutOfRange: isOutOfRange))
                }
            }
        }

        return sugarData.sorted { $0.timestamp < $1.timestamp }
    }

    private func getYRange(for data: [SugarData]) -> ClosedRange<Double> {
        let maxValue = data.map { $0.value }.max() ?? 0
        let defaultMax = 200.0
        return 0...(maxValue > Int((defaultMax)) ? Double(((maxValue + 9) / 10) * 10) : defaultMax)
    }

    @ChartContentBuilder
    private func fastingLineMarks(data: [SugarData]) -> some ChartContent {
        ForEach(data.filter { $0.type == .fasting }) { entry in
            LineMark(
                x: .value("Time", entry.timestamp, unit: period == "Daily" ? .minute : .day),
                y: .value("Value", entry.value),
                series: .value("Type", "Fasting")
            )
            .foregroundStyle(Color.orange)
            .lineStyle(StrokeStyle(lineWidth: 2))
            .symbol(Circle().strokeBorder(lineWidth: 2))
            .annotation(position: .top) {
                Text("\(entry.value)")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        }
    }


    @ChartContentBuilder
    private func afterMealLineMarks(data: [SugarData]) -> some ChartContent {
        ForEach(data.filter { $0.type == .afterMeal }) { entry in
            LineMark(
                x: .value("Time", entry.timestamp, unit: period == "Daily" ? .minute : .day),
                y: .value("Value", entry.value),
                series: .value("Type", "After Meal")
            )
            .foregroundStyle(Color.purple)
            .lineStyle(StrokeStyle(lineWidth: 2))
            .symbol(Circle().strokeBorder(lineWidth: 2))
            .annotation(position: .top) {
                Text("\(entry.value)")
                    .font(.caption2)
                    .foregroundColor(.purple)
            }
        }
    }

    @ChartContentBuilder
    private func thresholdMarks() -> some ChartContent {
        if let fastingThreshold = fastingThreshold {
            RuleMark(y: .value("Min Fasting", fastingThreshold.min))
                .foregroundStyle(.orange.opacity(0.7))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
            RuleMark(y: .value("Max Fasting", fastingThreshold.max))
                .foregroundStyle(.orange.opacity(0.7))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
        }
        if let afterMealThreshold = afterMealThreshold {
            RuleMark(y: .value("Min After Meal", afterMealThreshold.min))
                .foregroundStyle(.purple.opacity(0.7))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
            RuleMark(y: .value("Max After Meal", afterMealThreshold.max))
                .foregroundStyle(.purple.opacity(0.7))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
        }
    }

    private var legendView: some View {
        HStack(spacing: 16) {
            HStack(spacing: 4) {
                Rectangle()
                    .fill(Color.orange)
                    .frame(width: 12, height: 8)
                    .cornerRadius(2)
                Text("Fasting")
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            HStack(spacing: 4) {
                Rectangle()
                    .fill(Color.purple)
                    .frame(width: 12, height: 8)
                    .cornerRadius(2)
                Text("After Meal")
                    .font(.caption)
                    .foregroundColor(.primary)
            }
//            HStack(spacing: 4) {
//                Rectangle()
//                    .fill(Color.red)
//                    .frame(width: 12, height: 8)
//                    .cornerRadius(2)
//                Text("Out of Range")
//                    .font(.caption)
//                    .foregroundColor(.primary)
//            }
        }
        .padding(.top, 8)
    }

    var body: some View {
        let data = prepareSugarData()
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date = period == "Daily" ? calendar.startOfDay(for: now) :
                             period == "Weekly" ? calendar.date(byAdding: .day, value: -6, to: now) ?? now :
                             calendar.date(byAdding: .day, value: -29, to: now) ?? now

        VStack(alignment: .leading) {
            if data.isEmpty {
                Text("No sugar readings available for \(period.lowercased()) period")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            } else {
                Chart {
                    fastingLineMarks(data: data)
                    afterMealLineMarks(data: data)
                    thresholdMarks()
                }
                .chartXAxis {
                    if period == "Daily" {
                        AxisMarks(
                            values: stride(from: 0, through: 23, by: 3).map {
                                calendar.date(bySettingHour: $0, minute: 0, second: 0, of: startDate)!
                            }
                        ) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(.gray.opacity(0.3))
                            AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .abbreviated)))
                                .font(.caption)
                        }
                    } else if period == "Monthly" {
                        AxisMarks(
                            values: stride(from: 0, through: 29, by: 5).map {
                                calendar.date(byAdding: .day, value: -$0, to: now)!
                            }
                        ) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(.gray.opacity(0.3))
                            AxisValueLabel(format: .dateTime.day().month())
                                .font(.caption)
                        }
                    } else {
                        AxisMarks(values: .stride(by: .day)) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(.gray.opacity(0.3))
                            AxisValueLabel(format: .dateTime.day().month())
                                .font(.caption)
                        }
                    }
                }
                .chartXScale(domain: {
                    if period == "Daily" {
                        let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now)!
                        return startDate...end
                    } else {
                        return startDate...now
                    }
                }())
                .chartYScale(domain: getYRange(for: data))
                .chartYAxis {
                    AxisMarks(position: .leading) {
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(.gray.opacity(0.3))
                        AxisValueLabel()
                            .font(.caption)
                    }
                }
                .frame(height: 220)
            }

            legendView
        }
    }
}

// MARK: - HealthReportsScreen
struct HealthReportsScreen: View {
    let medicinesCount: Int
    @State private var selectedReportPeriod: String = "Daily"
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.modelContext) private var modelContext
    @Query private var userSettings: [UserSettings]
    @State private var showShareSheet: Bool = false
    @State private var pdfURL: URL?
    @State private var refreshID = UUID() // For forcing chart refresh

    private var currentUserSettings: UserSettings? {
        userSettings.first { $0.userID == authManager.currentUserUID }
    }

    private func checkForMissedDoses() {
        guard let userSettings = currentUserSettings, let medicines = userSettings.medicines else { return }
        let calendar = Calendar.current
        let today = Date()
        let todayStartOfDay = calendar.startOfDay(for: today)
        var changed = false

        for med in medicines {
            if let scheduledDoses = med.scheduledDoses {
                for dose in scheduledDoses {
                    let components = calendar.dateComponents([.hour, .minute], from: dose.time)
                    guard let doseTimeToday = calendar.date(bySettingHour: components.hour!,
                                                            minute: components.minute!,
                                                            second: 0,
                                                            of: today) else {
                        continue
                    }

                    if doseTimeToday <= today && !dose.isPending {
                        let existingEvent = med.doseLogEvents?.first { event in
                            event.scheduledDose?.id == dose.id &&
                            calendar.isDate(event.dateRecorded, inSameDayAs: todayStartOfDay)
                        }

                        if existingEvent == nil {
                            let newEvent = DoseLogEvent(
                                timestamp: doseTimeToday,
                                isTaken: false,
                                scheduledDose: dose,
                                medicine: med,
                                dateRecorded: todayStartOfDay
                            )
                            newEvent.userSettings = med.userSettings
                            med.doseLogEvents = med.doseLogEvents ?? []
                            med.doseLogEvents?.append(newEvent)
                            modelContext.insert(newEvent)
                            changed = true
                        }
                    }
                }
            }
        }

        if changed {
            do {
                try modelContext.save()
            } catch {
                print("Error saving missed dose events: \(error)")
            }
        }
    }

    private func adherenceSummary() -> String {
        guard let userSettings = currentUserSettings, let medicines = userSettings.medicines else { return "N/A" }
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date
        switch selectedReportPeriod {
        case "Daily":
            startDate = calendar.startOfDay(for: now)
            checkForMissedDoses()
        case "Weekly":
            startDate = calendar.date(byAdding: .day, value: -6, to: now) ?? now
        case "Monthly":
            startDate = calendar.date(byAdding: .day, value: -29, to: now) ?? now
        default:
            startDate = now
        }

        var totalDosesDue = 0
        var totalDosesTaken = 0

        for med in medicines {
            guard let scheduledDoses = med.scheduledDoses, let doseLogEvents = med.doseLogEvents else { continue }

            if selectedReportPeriod == "Daily" {
                let dosesDueToday = scheduledDoses.filter { dose in
                    let components = calendar.dateComponents([.hour, .minute], from: dose.time)
                    guard let doseTimeToday = calendar.date(bySettingHour: components.hour!,
                                                            minute: components.minute!,
                                                            second: 0,
                                                            of: now) else { return false }
                    return doseTimeToday <= now
                }
                totalDosesDue += dosesDueToday.count

                for dose in dosesDueToday {
                    let takenEvent = doseLogEvents.first { event in
                        event.scheduledDose?.id == dose.id &&
                        calendar.isDate(event.dateRecorded, inSameDayAs: startDate) &&
                        event.isTaken
                    }
                    if takenEvent != nil {
                        totalDosesTaken += 1
                    }
                }
            } else {
                let filteredEvents = doseLogEvents.filter { $0.dateRecorded >= startDate && $0.dateRecorded <= now }
                totalDosesDue += filteredEvents.count
                totalDosesTaken += filteredEvents.filter { $0.isTaken }.count
            }
        }

        totalDosesTaken = min(totalDosesTaken, totalDosesDue)
        return totalDosesDue > 0 ? String(format: "%.0f%%", Double(totalDosesTaken) / Double(totalDosesDue) * 100) : "N/A"
    }

    private func bpSummary() -> String {
        guard let userSettings = currentUserSettings, let readings = userSettings.vitalReadings else { return "N/A" }
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date
        switch selectedReportPeriod {
        case "Daily":
            startDate = calendar.startOfDay(for: now)
        case "Weekly":
            startDate = calendar.date(byAdding: .day, value: -6, to: now) ?? now
        case "Monthly":
            startDate = calendar.date(byAdding: .day, value: -29, to: now) ?? now
        default:
            startDate = now
        }

        let bpReadings = readings.filter { $0.type == .bp && $0.date >= startDate && $0.date <= now }
        let validSystolicReadings = bpReadings.compactMap { $0.systolic }
        let validDiastolicReadings = bpReadings.compactMap { $0.diastolic }

        let avgSystolic = validSystolicReadings.isEmpty ? 0 : validSystolicReadings.reduce(0, +) / validSystolicReadings.count
        let avgDiastolic = validDiastolicReadings.isEmpty ? 0 : validDiastolicReadings.reduce(0, +) / validDiastolicReadings.count
        return bpReadings.isEmpty ? "N/A" : "\(avgSystolic)/\(avgDiastolic)"
    }

    private func sugarSummary() -> String {
        guard let userSettings = currentUserSettings, let readings = userSettings.vitalReadings else { return "N/A" }
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date
        switch selectedReportPeriod {
        case "Daily":
            startDate = calendar.startOfDay(for: now)
        case "Weekly":
            startDate = calendar.date(byAdding: .day, value: -6, to: now) ?? now
        case "Monthly":
            startDate = calendar.date(byAdding: .day, value: -29, to: now) ?? now
        default:
            startDate = now
        }

        let sugarReadings = readings.filter { $0.type == .sugar && $0.date >= startDate && $0.date <= now }
        let fastingReadings = sugarReadings.filter { $0.sugarReadingType == .fasting }.compactMap { $0.sugarLevel }
        let afterMealReadings = sugarReadings.filter { $0.sugarReadingType == .afterMeal }.compactMap { $0.sugarLevel }

        let avgFasting = fastingReadings.isEmpty ? 0 : fastingReadings.reduce(0, +) / fastingReadings.count
        let avgAfterMeal = afterMealReadings.isEmpty ? 0 : afterMealReadings.reduce(0, +) / afterMealReadings.count
        return sugarReadings.isEmpty ? "N/A" : fastingReadings.isEmpty ? "After Meal: \(avgAfterMeal)" : afterMealReadings.isEmpty ? "Fasting: \(avgFasting)" : "Fasting: \(avgFasting), After Meal: \(avgAfterMeal)"
    }

    private func generatePDF() -> URL? {
        let pdfData = NSMutableData()
        let pageBounds = CGRect(x: 0, y: 0, width: 595, height: 842) // A4 size
        UIGraphicsBeginPDFContextToData(pdfData, pageBounds, nil)
        UIGraphicsBeginPDFPageWithInfo(pageBounds, nil)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndPDFContext()
            print("Error: Failed to get PDF context")
            return nil
        }

        var yOffset: CGFloat = 50
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.black
        ]
        let boldAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 12),
            .foregroundColor: UIColor.black
        ]
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 18),
            .foregroundColor: UIColor.black
        ]

        // Title
        let title = "\(selectedReportPeriod) Health Report — \(Date().formatted(date: .long, time: .omitted))"
        let titleRect = title.boundingRect(with: CGSize(width: pageBounds.width - 100, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: titleAttributes, context: nil)
        title.draw(in: CGRect(x: 50, y: yOffset, width: pageBounds.width - 100, height: titleRect.height), withAttributes: titleAttributes)
        yOffset += titleRect.height + 20

        // User Info
        let userInfo = "User: \(authManager.currentUserDisplayName ?? "N/A")\nEmail: \(authManager.currentUserUID ?? "N/A")"
        let userInfoRect = userInfo.boundingRect(with: CGSize(width: pageBounds.width - 100, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
        userInfo.draw(in: CGRect(x: 50, y: yOffset, width: pageBounds.width - 100, height: userInfoRect.height), withAttributes: attributes)
        yOffset += userInfoRect.height + 20

        // Adherence Table
        yOffset = drawTable(
            title: "Medicine Adherence",
            headers: ["Medicine", "Date", "Status"],
            data: prepareAdherenceTableData(),
            at: CGPoint(x: 50, y: yOffset),
            bounds: pageBounds,
            context: context,
            attributes: attributes,
            boldAttributes: boldAttributes
        )

        // BP Table
        yOffset = drawTable(
            title: "Blood Pressure",
            headers: ["Date", "Systolic", "Diastolic", "Status"],
            data: prepareBPTableData(),
            at: CGPoint(x: 50, y: yOffset),
            bounds: pageBounds,
            context: context,
            attributes: attributes,
            boldAttributes: boldAttributes
        )

        // Sugar Table
        yOffset = drawTable(
            title: "Blood Sugar",
            headers: ["Date", "Fasting", "After Meal", "Status"],
            data: prepareSugarTableData(),
            at: CGPoint(x: 50, y: yOffset),
            bounds: pageBounds,
            context: context,
            attributes: attributes,
            boldAttributes: boldAttributes
        )

        UIGraphicsEndPDFContext()

        // Save PDF to temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(selectedReportPeriod)_Health_Report_\(UUID().uuidString).pdf")
        do {
            try pdfData.write(to: tempURL)
            print("PDF saved successfully at: \(tempURL)")
            return tempURL
        } catch {
            print("Error saving PDF: \(error)")
            return nil
        }
    }

    private func drawTable(title: String, headers: [String], data: [[String]], at point: CGPoint, bounds: CGRect, context: CGContext, attributes: [NSAttributedString.Key: Any], boldAttributes: [NSAttributedString.Key: Any]) -> CGFloat {
        var yOffset = point.y
        let columnWidth = (bounds.width - 100) / CGFloat(headers.count)

        // Draw title
        let titleRect = title.boundingRect(with: CGSize(width: bounds.width - 100, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: boldAttributes, context: nil)
        title.draw(in: CGRect(x: point.x, y: yOffset, width: bounds.width - 100, height: titleRect.height), withAttributes: boldAttributes)
        yOffset += titleRect.height + 10

        // Draw headers
        for (index, header) in headers.enumerated() {
            let headerRect = header.boundingRect(with: CGSize(width: columnWidth, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: boldAttributes, context: nil)
            header.draw(in: CGRect(x: point.x + CGFloat(index) * columnWidth, y: yOffset, width: columnWidth, height: headerRect.height), withAttributes: boldAttributes)
        }
        yOffset += 20

        // Draw data rows
        for row in data {
            for (index, cell) in row.enumerated() {
                let cellRect = cell.boundingRect(with: CGSize(width: columnWidth, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
                cell.draw(in: CGRect(x: point.x + CGFloat(index) * columnWidth, y: yOffset, width: columnWidth, height: cellRect.height), withAttributes: attributes)
            }
            yOffset += 20
        }
        return yOffset + 20
    }

    private func prepareAdherenceTableData() -> [[String]] {
        guard let userSettings = currentUserSettings, let medicines = userSettings.medicines else { return [] }
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date
        switch selectedReportPeriod {
        case "Daily":
            startDate = calendar.startOfDay(for: now)
        case "Weekly":
            startDate = calendar.date(byAdding: .day, value: -6, to: now) ?? now
        case "Monthly":
            startDate = calendar.date(byAdding: .day, value: -29, to: now) ?? now
        default:
            startDate = now
        }

        var rows: [[String]] = []
        for medicine in medicines {
            guard let doseLogEvents = medicine.doseLogEvents else { continue }
            let filteredEvents = doseLogEvents.filter { $0.dateRecorded >= startDate && $0.dateRecorded <= now }
            for event in filteredEvents {
                rows.append([
                    medicine.name,
                    event.dateRecorded.formatted(date: .abbreviated, time: .shortened),
                    event.isTaken ? "Taken" : "Missed"
                ])
            }
        }
        return rows
    }

    private func prepareBPTableData() -> [[String]] {
        guard let userSettings = currentUserSettings, let readings = userSettings.vitalReadings else { return [] }
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date
        switch selectedReportPeriod {
        case "Daily":
            startDate = calendar.startOfDay(for: now)
        case "Weekly":
            startDate = calendar.date(byAdding: .day, value: -6, to: now) ?? now
        case "Monthly":
            startDate = calendar.date(byAdding: .day, value: -29, to: now) ?? now
        default:
            startDate = now
        }

        let bpReadings = readings.filter { $0.type == .bp && $0.date >= startDate && $0.date <= now }
        return bpReadings.map { reading in
            [
                reading.date.formatted(date: .abbreviated, time: .shortened),
                reading.systolic?.description ?? "N/A",
                reading.diastolic?.description ?? "N/A",
                reading.getStatus()
            ]
        }
    }

    private func prepareSugarTableData() -> [[String]] {
        guard let userSettings = currentUserSettings, let readings = userSettings.vitalReadings else { return [] }
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date
        switch selectedReportPeriod {
        case "Daily":
            startDate = calendar.startOfDay(for: now)
        case "Weekly":
            startDate = calendar.date(byAdding: .day, value: -6, to: now) ?? now
        case "Monthly":
            startDate = calendar.date(byAdding: .day, value: -29, to: now) ?? now
        default:
            startDate = now
        }

        let sugarReadings = readings.filter { $0.type == .sugar && $0.date >= startDate && $0.date <= now }
        var rows: [[String]] = []
        let dates = Set(sugarReadings.map { calendar.startOfDay(for: $0.date) }).sorted()
        for date in dates {
            let fasting = sugarReadings.first { calendar.isDate($0.date, inSameDayAs: date) && $0.sugarReadingType == .fasting }
            let afterMeal = sugarReadings.first { calendar.isDate($0.date, inSameDayAs: date) && $0.sugarReadingType == .afterMeal }
            rows.append([
                date.formatted(date: .abbreviated, time: .omitted),
                fasting?.sugarLevel?.description ?? "N/A",
                afterMeal?.sugarLevel?.description ?? "N/A",
                fasting?.getStatus() ?? afterMeal?.getStatus() ?? "N/A"
            ])
        }
        return rows
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        SMAMedicineTrackerHeader()
                        SMAMedicineTrackerStats(medicinesCount: medicinesCount)

                        // Subheading
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Generate and view your health analytics")
                                .font(.subheadline)
                                .foregroundColor(.gray.opacity(0.7))
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 10)

                        // Period Selection Buttons
                        HStack(spacing: 10) {
                            ReportPeriodButton(title: "Daily", isSelected: selectedReportPeriod == "Daily") {
                                selectedReportPeriod = "Daily"
                                refreshID = UUID()
                            }
                            ReportPeriodButton(title: "Weekly", isSelected: selectedReportPeriod == "Weekly") {
                                selectedReportPeriod = "Weekly"
                                refreshID = UUID()
                            }
                            ReportPeriodButton(title: "Monthly", isSelected: selectedReportPeriod == "Monthly") {
                                selectedReportPeriod = "Monthly"
                                refreshID = UUID()
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 10)

                        // Data Cards
                        ReportDataCardView(
                            value: adherenceSummary(),
                            description: "\(selectedReportPeriod) Adherence",
                            iconName: "chart.line.uptrend.xyaxis",
                            tintColor: .blue,
                            trend: nil
                        )
                        .padding(.horizontal, 10)

                        ReportDataCardView(
                            value: bpSummary(),
                            description: "Avg BP \(selectedReportPeriod)",
                            iconName: "waveform.path",
                            tintColor: .green,
                            trend: nil
                        )
                        .padding(.horizontal, 10)

                        ReportDataCardView(
                            value: sugarSummary(),
                            description: "Avg Sugar \(selectedReportPeriod)",
                            iconName: "waveform.path",
                            tintColor: .orange,
                            trend: nil
                        )
                        .padding(.horizontal, 10)
                        
                        // Charts Section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Medicine Adherence")
                                .font(.headline)
                                .foregroundColor(.primary)
                            AdherenceChartView(
                                medicines: currentUserSettings?.medicines ?? [],
                                period: selectedReportPeriod,
                                userSettings: currentUserSettings
                            )
                            .frame(height: 200)
                            .id(refreshID)
                        }
                        .padding(.horizontal)
//                        .padding(.vertical)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Blood Pressure")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.vertical)
                            BPChartView(
                                vitalReadings: currentUserSettings?.vitalReadings ?? [],
                                period: selectedReportPeriod,
                                bpThreshold: currentUserSettings?.alertSettings.bpThreshold
                            )
                            .frame(height: 200)
                            .id(refreshID)
                        }
                        .padding(.horizontal)
                        .padding(.vertical)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Blood Sugar")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.vertical,20)

                            SugarChartView(
                                vitalReadings: currentUserSettings?.vitalReadings ?? [],
                                period: selectedReportPeriod,
                                fastingThreshold: currentUserSettings?.alertSettings.fastingSugarThreshold,
                                afterMealThreshold: currentUserSettings?.alertSettings.afterMealSugarThreshold
                            )
                            .frame(height: 200)
                            .id(refreshID)
                        }
                        .padding(.horizontal)
                        .padding(.vertical)

                        // PDF Download Button
                        Button(action: {
                            pdfURL = generatePDFEnhanced()
                            if let actualURL = pdfURL {
                                print("hak\(actualURL)")  // Clean print
                            }
                            if pdfURL != nil {
                                print("pdf\(pdfURL)")
                                showShareSheet = true
                            } else {
                                print("Failed to generate PDF")
                            }
                        }) {
                            Label("Download PDF", systemImage: "arrow.down.doc.fill")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)

                        Spacer()
                    }
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 60)
                }
            }
            .navigationTitle("Health Reports")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showShareSheet) {
                if let url = pdfURL {
                    
                    ShareSheet(activityItems: [url])
                }
            }
            .onAppear {
                selectedReportPeriod = "Daily"
                refreshID = UUID()
            }
        }
    }
}

extension HealthReportsScreen {
    // MARK: - Enhanced PDF Generation
    private func generateEnhancedPDF() -> URL? {
        let pdfData = NSMutableData()
        let pageBounds = CGRect(x: 0, y: 0, width: 595, height: 842) // A4 size
        UIGraphicsBeginPDFContextToData(pdfData, pageBounds, nil)
        
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndPDFContext()
            return nil
        }
        
        var currentPage = 1
        var yOffset: CGFloat = 50
        let pageMargin: CGFloat = 50
        let pageHeight = pageBounds.height - 100 // Leave margin at bottom
        
        // Font definitions
        let titleFont = UIFont.boldSystemFont(ofSize: 18)
        let headerFont = UIFont.boldSystemFont(ofSize: 14)
        let subHeaderFont = UIFont.systemFont(ofSize: 12, weight: .medium)
        let bodyFont = UIFont.systemFont(ofSize: 10)
        let captionFont = UIFont.systemFont(ofSize: 9)
        
        // Color definitions
        let primaryColor = UIColor.black
        let headerColor = UIColor.systemBlue
        let borderColor = UIColor.lightGray
        
        // Start first page
        UIGraphicsBeginPDFPageWithInfo(pageBounds, nil)
        
        // Helper function to check if new page is needed
        func checkNewPage() -> Bool {
            if yOffset > pageHeight {
                currentPage += 1
                UIGraphicsBeginPDFPageWithInfo(pageBounds, nil)
                yOffset = pageMargin
                return true
            }
            return false
        }
        
        // Draw header
        yOffset = drawReportHeader(at: yOffset, bounds: pageBounds, fonts: (titleFont, headerFont, bodyFont), selectedReportPeriod: selectedReportPeriod)
        
        // Medicine Adherence Section
        let medicineData = prepareEnhancedMedicineData()
        if !medicineData.isEmpty {
            yOffset = drawMedicineAdherenceTable(
                data: medicineData,
                at: yOffset,
                bounds: pageBounds,
                fonts: (headerFont, subHeaderFont, bodyFont),
                context: context,
                pageHeight: pageHeight,
                pageMargin: pageMargin,
                titleFont: titleFont,
                headerFont: headerFont,
                bodyFont: bodyFont
            )
            checkNewPage()
        }
        
        // Blood Pressure Section
        let bpData = prepareEnhancedBPData()
        if !bpData.isEmpty {
            if checkNewPage() {
                yOffset = drawReportHeader(at: yOffset, bounds: pageBounds, fonts: (titleFont, headerFont, bodyFont), selectedReportPeriod: selectedReportPeriod)
            }
            yOffset = drawBloodPressureTable(
                data: bpData,
                at: yOffset,
                bounds: pageBounds,
                fonts: (headerFont, subHeaderFont, bodyFont),
                context: context,
                pageHeight: pageHeight,
                pageMargin: pageMargin,
                titleFont: titleFont,
                headerFont: headerFont,
                bodyFont: bodyFont
            )
        }
        
        // Blood Sugar Section
        let sugarData = prepareEnhancedSugarData()
        if !sugarData.isEmpty {
            if checkNewPage() {
                yOffset = drawReportHeader(at: yOffset, bounds: pageBounds, fonts: (titleFont, headerFont, bodyFont), selectedReportPeriod: selectedReportPeriod)
            }
            yOffset = drawBloodSugarTable(
                data: sugarData,
                at: yOffset,
                bounds: pageBounds,
                fonts: (headerFont, subHeaderFont, bodyFont),
                context: context,
                pageHeight: pageHeight,
                pageMargin: pageMargin,
                titleFont: titleFont,
                headerFont: headerFont,
                bodyFont: bodyFont
            )
        }
        
        // Summary Section
        if checkNewPage() {
            yOffset = drawReportHeader(at: yOffset, bounds: pageBounds, fonts: (titleFont, headerFont, bodyFont), selectedReportPeriod: selectedReportPeriod)
        }
        yOffset = drawSummarySection(
            at: yOffset,
            bounds: pageBounds,
            fonts: (headerFont, bodyFont),
            selectedReportPeriod: selectedReportPeriod,
            currentUserSettings: currentUserSettings
        )
        
        // Footer on last page
//        drawFooter(bounds: pageBounds, font: captionFont, pageNumber: currentPage)
        // 🟦 STEP: Render Chart to Image
        let chartImage = AdherenceChartView(
            medicines: currentUserSettings?.medicines ?? [],
            period: selectedReportPeriod,
            userSettings: currentUserSettings
        ).snapshot(width: 500, height: 300)
        
        
        // 🟦 Add a new page for chart
        UIGraphicsBeginPDFPageWithInfo(pageBounds, nil)
        yOffset = pageMargin

        // 🟦 Draw section title
        let chartTitle = "\(selectedReportPeriod) Medicine Adherence Chart"
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: primaryColor
        ]
        chartTitle.draw(at: CGPoint(x: pageMargin, y: yOffset), withAttributes: titleAttributes)
        yOffset += 30

        // 🟦 Draw chart image
        let chartRect = CGRect(x: pageMargin, y: yOffset, width: 500, height: 300)
        chartImage.draw(in: chartRect)
        yOffset += chartRect.height + 20
        
        
        // ✅ Create BP chart image
        let bpChartImage = BPChartView(
            vitalReadings: currentUserSettings?.vitalReadings ?? [], // your array
            period: selectedReportPeriod, // e.g., "Weekly"
            bpThreshold: currentUserSettings?.alertSettings.bpThreshold  // your BP threshold
        ).snapshot(width: 500, height: 300)

        
        // ✅ Add new page for BP chart
//        UIGraphicsBeginPDFPageWithInfo(pageBounds, nil)
//        yOffset = pageMargin

        // ✅ Title
        let bpChartTitle = "\(selectedReportPeriod) Blood Pressure Chart"
        let titleAttributes1: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: primaryColor
        ]
        bpChartTitle.draw(at: CGPoint(x: pageMargin, y: yOffset), withAttributes: titleAttributes1)
        yOffset += 30

        // ✅ Chart image
        let chartRect1 = CGRect(x: pageMargin, y: yOffset, width: 500, height: 300)
        bpChartImage.draw(in: chartRect1)
        yOffset += chartRect1.height + 20
        
        let sugarChartImage = SugarChartView(
                vitalReadings: currentUserSettings?.vitalReadings ?? [],
                period: selectedReportPeriod,
                fastingThreshold: currentUserSettings?.alertSettings.fastingSugarThreshold,
                afterMealThreshold: currentUserSettings?.alertSettings.afterMealSugarThreshold
            ).snapshot(width: 500, height: 300)
        
        UIGraphicsBeginPDFPageWithInfo(pageBounds, nil)
            yOffset = pageMargin
            
            // ✅ Title
            let sugarTitle = "\(selectedReportPeriod) Sugar Level Chart"
            let sugarTitleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: primaryColor
            ]
            sugarTitle.draw(at: CGPoint(x: pageMargin, y: yOffset), withAttributes: sugarTitleAttributes)
            yOffset += 30
            
            // ✅ Draw chart image
            let sugarChartRect = CGRect(x: pageMargin, y: yOffset, width: 500, height: 300)
            sugarChartImage.draw(in: sugarChartRect)
            yOffset += sugarChartRect.height + 20


        // Footer on last page
        drawFooter(bounds: pageBounds, font: captionFont, pageNumber: currentPage)
        
        UIGraphicsEndPDFContext()
        
        // Save PDF
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss" // Safe format for file names
        let dateString = dateFormatter.string(from: Date())

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(selectedReportPeriod)_Health_Report_\(dateString).pdf")
        do {
            try pdfData.write(to: tempURL)
            print("PDF saved successfully at: \(tempURL)")
            return tempURL
        } catch {
            print("Error saving PDF: \(error)")
            return nil
        }
       


    }
    
    
    
    // MARK: - Enhanced Data Preparation
    private func prepareEnhancedMedicineData() -> [MedicineReportRow] {
        guard let userSettings = currentUserSettings, let medicines = userSettings.medicines else { return [] }
        
        let calendar = Calendar.current
        let now = Date()
        let dateRange = getDateRangeForPeriod()
        
        var rows: [MedicineReportRow] = []
        
        // Iterate over all days in the date range
        for date in dateRange {
            let dayStart = calendar.startOfDay(for: date)
            
            for medicine in medicines {
                guard let scheduledDoses = medicine.scheduledDoses,
                      let doseLogEvents = medicine.doseLogEvents else { continue }
                
                // Check all scheduled doses for this day
                for dose in scheduledDoses {
                    let components = calendar.dateComponents([.hour, .minute], from: dose.time)
                    guard let doseTimeOnDay = calendar.date(
                        bySettingHour: components.hour!,
                        minute: components.minute!,
                        second: 0,
                        of: date
                    ) else { continue }
                    
                    // Include if dose time has passed or it's a past day
                    if date < calendar.startOfDay(for: now) || doseTimeOnDay <= now {
                        let logEvent = doseLogEvents.first { event in
                            event.scheduledDose?.id == dose.id &&
                            calendar.isDate(event.dateRecorded, inSameDayAs: dayStart)
                        }
                        
                        let status = logEvent?.isTaken == true ? "Taken" : logEvent != nil ? "Missed" : "Nil"
                        let actualTime = logEvent?.timestamp
                        
                        rows.append(MedicineReportRow(
                            date: date,
                            medicine: medicine.name,
                            scheduleTime: dose.time,
                            status: status,
                            actualTime: actualTime
                        ))
                    }
                }
                
                // Add placeholder for days with no doses
                if !rows.contains(where: { calendar.isDate($0.date, inSameDayAs: dayStart) && $0.medicine == medicine.name }) {
                    rows.append(MedicineReportRow(
                        date: date,
                        medicine: medicine.name,
                        scheduleTime: now, // Placeholder time
                        status: "Nil",
                        actualTime: nil
                    ))
                }
            }
        }
        
        // Sort by date (desc) then by time (asc)
        return rows.sorted { first, second in
            if first.date == second.date {
                return first.scheduleTime < second.scheduleTime
            }
            return first.date > second.date
        }
    }
    
    private func prepareEnhancedBPData() -> [BPReportRow] {
        guard let userSettings = currentUserSettings, let readings = userSettings.vitalReadings else { return [] }
        
        let dateRange = Set(getDateRangeForPeriod())
        let bpReadings = readings.filter {
            $0.type == .bp && dateRange.contains(Calendar.current.startOfDay(for: $0.date))
        }
        
        return bpReadings.map { reading in
            BPReportRow(
                date: reading.date,
                time: reading.time,
                systolic: reading.systolic ?? 0,
                diastolic: reading.diastolic ?? 0,
                status: reading.getStatus()
            )
        }.sorted { $0.date > $1.date } // Most recent first
    }
    
    private func prepareEnhancedSugarData() -> [SugarReportRow] {
        guard let userSettings = currentUserSettings, let readings = userSettings.vitalReadings else { return [] }
        
        let dateRange = Set(getDateRangeForPeriod())
        let sugarReadings = readings.filter {
            $0.type == .sugar && dateRange.contains(Calendar.current.startOfDay(for: $0.date))
        }
        
        return sugarReadings.map { reading in
            SugarReportRow(
                date: reading.date,
                time: reading.time,
                type: reading.sugarReadingType?.rawValue ?? "Unknown",
                value: reading.sugarLevel ?? 0,
                status: reading.getStatus()
            )
        }.sorted { $0.date > $1.date } // Most recent first
    }
    
    // MARK: - Table Drawing Functions
    private func drawReportHeader(at yOffset: CGFloat, bounds: CGRect, fonts: (UIFont, UIFont, UIFont), selectedReportPeriod: String) -> CGFloat {
        var currentY = yOffset
        let margin: CGFloat = 50
        let pageWidth = bounds.width - (margin * 2)
        
        // Main title with better styling
        let title = "🏥 \(selectedReportPeriod) Health Report"
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: fonts.0,
            .foregroundColor: UIColor.systemBlue
        ]
        let titleSize = title.size(withAttributes: titleAttributes)
        let titleX = margin + (pageWidth - titleSize.width) / 2 // Center the title
        title.draw(at: CGPoint(x: titleX, y: currentY), withAttributes: titleAttributes)
        currentY += titleSize.height + 15
        
        // Draw a decorative line under title
        let context = UIGraphicsGetCurrentContext()!
        context.setStrokeColor(UIColor.systemBlue.cgColor)
        context.setLineWidth(2)
        context.move(to: CGPoint(x: margin + 50, y: currentY))
        context.addLine(to: CGPoint(x: bounds.width - margin - 50, y: currentY))
        context.strokePath()
        currentY += 20
        
        // Patient info section
        let patientName = authManager.currentUserDisplayName ?? "Patient"
        let patientInfo = "Patient: \(patientName)"
        let patientAttributes: [NSAttributedString.Key: Any] = [
            .font: fonts.1,
            .foregroundColor: UIColor.darkGray
        ]
        patientInfo.draw(at: CGPoint(x: margin, y: currentY), withAttributes: patientAttributes)
        currentY += 25
        
        // Date range with better formatting
        let dateRange = getDateRangeForPeriod()
        let startDate = dateRange.min() ?? Date()
        let endDate = dateRange.max() ?? Date()
        
        var periodText: String
        if selectedReportPeriod == "Daily" {
            periodText = "Report Date: \(startDate.formatted(date: .abbreviated, time: .omitted))"
        } else {
            periodText = "Report Period: \(startDate.formatted(date: .abbreviated, time: .omitted)) - \(endDate.formatted(date: .abbreviated, time: .omitted))"
        }
        
        let periodAttributes: [NSAttributedString.Key: Any] = [
            .font: fonts.2,
            .foregroundColor: UIColor.systemGray
        ]
        periodText.draw(at: CGPoint(x: margin, y: currentY), withAttributes: periodAttributes)
        currentY += 20
        
        // Generated timestamp
        let generatedText = "Generated: \(Date().formatted(date: .abbreviated, time: .standard))"
        generatedText.draw(at: CGPoint(x: margin, y: currentY), withAttributes: periodAttributes)
        currentY += 35
        
        return currentY
    }
    
    private func drawMedicineAdherenceTable(
        data: [MedicineReportRow],
        at yOffset: CGFloat,
        bounds: CGRect,
        fonts: (UIFont, UIFont, UIFont),
        context: CGContext,
        pageHeight: CGFloat,
        pageMargin: CGFloat,
        titleFont: UIFont,
        headerFont: UIFont,
        bodyFont: UIFont
    ) -> CGFloat {
        var currentY = yOffset
        let margin: CGFloat = 50
        let tableWidth = bounds.width - (margin * 2)
        
        // Section title with icon
        let sectionTitle = "💊 Medicine Adherence Report"
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: fonts.0,
            .foregroundColor: UIColor.systemBlue
        ]
        let titleSize = sectionTitle.size(withAttributes: titleAttributes)
        sectionTitle.draw(at: CGPoint(x: margin, y: currentY), withAttributes: titleAttributes)
        currentY += titleSize.height + 20
        
        // Table headers with better width distribution
        let headers = ["Date", "Medicine Name", "Scheduled Time", "Status"]
        let columnWidths: [CGFloat] = [
            tableWidth * 0.18,  // Date - shorter
            tableWidth * 0.42,  // Medicine - wider for long names
            tableWidth * 0.22,  // Schedule Time - medium
            tableWidth * 0.18   // Status - shorter
        ]
        
        // Draw header row with enhanced styling
        currentY = drawTableRow(
            columns: headers,
            widths: columnWidths,
            at: CGPoint(x: margin, y: currentY),
            font: fonts.1,
            textColor: UIColor.white,
            backgroundColor: UIColor.systemBlue,
            context: context,
            isHeader: true
        )
        
        // Draw data rows with page break handling
        for (index, row) in data.enumerated() {
            let backgroundColor = index % 2 == 0 ? UIColor(red: 0.95, green: 0.97, blue: 1.0, alpha: 1.0) : UIColor.white
            let statusColor = row.status == "Taken" ? UIColor.systemGreen : row.status == "Nil" ? UIColor.lightGray : UIColor.systemRed
            
            let columns = [
                formatDate(row.date, style: .compact),
                row.medicine,
                row.status == "Nil" ? "N/A" : formatTime(row.scheduleTime),
                row.status.uppercased()
            ]
            
            // Check if adding this row will exceed page height
            let rowHeight = 30.0
            if currentY + rowHeight > pageHeight {
                // Move to next page
                UIGraphicsBeginPDFPageWithInfo(bounds, nil)
                currentY = pageMargin
                currentY = drawReportHeader(at: currentY, bounds: bounds, fonts: (titleFont, headerFont, bodyFont), selectedReportPeriod: selectedReportPeriod)
                currentY = drawTableRow(
                    columns: headers,
                    widths: columnWidths,
                    at: CGPoint(x: margin, y: currentY),
                    font: fonts.1,
                    textColor: UIColor.white,
                    backgroundColor: UIColor.systemBlue,
                    context: context,
                    isHeader: true
                )
            }
            
            currentY = drawTableRow(
                columns: columns,
                widths: columnWidths,
                at: CGPoint(x: margin, y: currentY),
                font: fonts.2,
                textColor: index == 3 ? statusColor : UIColor.black,
                backgroundColor: backgroundColor,
                context: context,
                isHeader: false
            )
        }
        
        // Add summary row
        let totalDoses = data.count
        let takenDoses = data.filter { $0.status == "Taken" }.count
        let adherencePercent = totalDoses > 0 ? (Double(takenDoses) / Double(totalDoses) * 100) : 0
        
        currentY += 10
        let summaryText = "Summary: \(takenDoses)/\(totalDoses) doses taken (\(String(format: "%.1f", adherencePercent))% adherence)"
        let summaryAttributes: [NSAttributedString.Key: Any] = [
            .font: fonts.1,
            .foregroundColor: adherencePercent >= 80 ? UIColor.systemGreen : UIColor.systemOrange
        ]
        summaryText.draw(at: CGPoint(x: margin, y: currentY), withAttributes: summaryAttributes)
        currentY += 25
        
        return currentY + 20
    }
    
    private func drawBloodPressureTable(
        data: [BPReportRow],
        at yOffset: CGFloat,
        bounds: CGRect,
        fonts: (UIFont, UIFont, UIFont),
        context: CGContext,
        pageHeight: CGFloat,
        pageMargin: CGFloat,
        titleFont: UIFont,
        headerFont: UIFont,
        bodyFont: UIFont
    ) -> CGFloat {
        var currentY = yOffset
        let margin: CGFloat = 50
        let tableWidth = bounds.width - (margin * 2)
        
        // Section title with better icon
        let sectionTitle = "🩺 Blood Pressure Readings"
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: fonts.0,
            .foregroundColor: UIColor.systemRed
        ]
        let titleSize = sectionTitle.size(withAttributes: titleAttributes)
        sectionTitle.draw(at: CGPoint(x: margin, y: currentY), withAttributes: titleAttributes)
        currentY += titleSize.height + 20
        
        // Table headers with optimized widths
        let headers = ["Date", "Time", "Systolic", "Diastolic", "Status"]
        let columnWidths: [CGFloat] = [
            tableWidth * 0.22,  // Date
            tableWidth * 0.18,  // Time
            tableWidth * 0.18,  // Systolic
            tableWidth * 0.18,  // Diastolic
            tableWidth * 0.24   // Status - wider for "Elevated" text
        ]
        
        // Draw header row
        currentY = drawTableRow(
            columns: headers,
            widths: columnWidths,
            at: CGPoint(x: margin, y: currentY),
            font: fonts.1,
            textColor: UIColor.white,
            backgroundColor: UIColor.systemRed,
            context: context,
            isHeader: true
        )
        
        // Draw data rows with page break handling
        for (index, row) in data.enumerated() {
            let backgroundColor = index % 2 == 0 ? UIColor(red: 1.0, green: 0.95, blue: 0.95, alpha: 1.0) : UIColor.white
            let statusColor = getStatusColor(for: row.status)
            
            let columns = [
                formatDate(row.date, style: .compact),
                formatTime(row.time),
                "\(row.systolic)",
                "\(row.diastolic)",
                row.status.uppercased()
            ]
            
            // Check if adding this row will exceed page height
            if currentY + 30 > pageHeight {
                // Move to next page
                UIGraphicsBeginPDFPageWithInfo(bounds, nil)
                currentY = pageMargin
                currentY = drawReportHeader(at: currentY, bounds: bounds, fonts: (titleFont, headerFont, bodyFont), selectedReportPeriod: selectedReportPeriod)
                currentY = drawTableRow(
                    columns: headers,
                    widths: columnWidths,
                    at: CGPoint(x: margin, y: currentY),
                    font: fonts.1,
                    textColor: UIColor.white,
                    backgroundColor: UIColor.systemRed,
                    context: context,
                    isHeader: true
                )
            }
            
            currentY = drawTableRow(
                columns: columns,
                widths: columnWidths,
                at: CGPoint(x: margin, y: currentY),
                font: fonts.2,
                textColor: UIColor.black,
                backgroundColor: backgroundColor,
                context: context,
                isHeader: false
            )
            
            // Add status indicator circle after drawing the row
            let statusIndicatorX = margin + columnWidths.dropLast().reduce(0, +) + columnWidths.last! - 15
            let statusIndicatorY = currentY - 20
            drawStatusIndicator(at: CGPoint(x: statusIndicatorX, y: statusIndicatorY), color: statusColor, context: context)
        }
        
        // Add BP summary
        if !data.isEmpty {
            let avgSystolic = data.map { $0.systolic }.reduce(0, +) / data.count
            let avgDiastolic = data.map { $0.diastolic }.reduce(0, +) / data.count
            
            currentY += 10
            let summaryText = "Average BP: \(avgSystolic)/\(avgDiastolic) mmHg (\(data.count) readings)"
            let summaryAttributes: [NSAttributedString.Key: Any] = [
                .font: fonts.1,
                .foregroundColor: UIColor.systemRed
            ]
            summaryText.draw(at: CGPoint(x: margin, y: currentY), withAttributes: summaryAttributes)
            currentY += 25
        }
        
        return currentY + 20
    }
    
    private func drawBloodSugarTable(
        data: [SugarReportRow],
        at yOffset: CGFloat,
        bounds: CGRect,
        fonts: (UIFont, UIFont, UIFont),
        context: CGContext,
        pageHeight: CGFloat,
        pageMargin: CGFloat,
        titleFont: UIFont,
        headerFont: UIFont,
        bodyFont: UIFont
    ) -> CGFloat {
        var currentY = yOffset
        let margin: CGFloat = 50
        let tableWidth = bounds.width - (margin * 2)
        
        // Section title
        let sectionTitle = "🍯 Blood Sugar Readings"
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: fonts.0,
            .foregroundColor: UIColor.systemOrange
        ]
        let titleSize = sectionTitle.size(withAttributes: titleAttributes)
        sectionTitle.draw(at: CGPoint(x: margin, y: currentY), withAttributes: titleAttributes)
        currentY += titleSize.height + 20
        
        // Table headers with optimized widths
        let headers = ["Date", "Time", "Reading Type", "Value (mg/dL)", "Status"]
        let columnWidths: [CGFloat] = [
            tableWidth * 0.18,  // Date
            tableWidth * 0.16,  // Time
            tableWidth * 0.22,  // Reading Type - wider for "After Meal"
            tableWidth * 0.20,  // Value with units
            tableWidth * 0.24   // Status
        ]
        
        // Draw header row
        currentY = drawTableRow(
            columns: headers,
            widths: columnWidths,
            at: CGPoint(x: margin, y: currentY),
            font: fonts.1,
            textColor: UIColor.white,
            backgroundColor: UIColor.systemOrange,
            context: context,
            isHeader: true
        )
        
        // Draw data rows with page break handling
        for (index, row) in data.enumerated() {
            let backgroundColor = index % 2 == 0 ? UIColor(red: 1.0, green: 0.97, blue: 0.9, alpha: 1.0) : UIColor.white
            let statusColor = getStatusColor(for: row.status)
            
            let readingTypeDisplay = row.type == "Fasting" ? "🌅 Fasting" : "🍽️ After Meal"
            let columns = [
                formatDate(row.date, style: .compact),
                formatTime(row.time),
                readingTypeDisplay,
                "\(row.value)",
                row.status.uppercased()
            ]
            
            if currentY + 30 > pageHeight {
                // Move to next page
                UIGraphicsBeginPDFPageWithInfo(bounds, nil)
                currentY = pageMargin
                currentY = drawReportHeader(at: currentY, bounds: bounds, fonts: (titleFont, headerFont, bodyFont), selectedReportPeriod: selectedReportPeriod)
                currentY = drawTableRow(
                    columns: headers,
                    widths: columnWidths,
                    at: CGPoint(x: margin, y: currentY),
                    font: fonts.1,
                    textColor: UIColor.white,
                    backgroundColor: UIColor.systemOrange,
                    context: context,
                    isHeader: true
                )
            }
            
            currentY = drawTableRow(
                columns: columns,
                widths: columnWidths,
                at: CGPoint(x: margin, y: currentY),
                font: fonts.2,
                textColor: UIColor.black,
                backgroundColor: backgroundColor,
                context: context,
                isHeader: false
            )
            
            // Add status indicator
            let statusIndicatorX = margin + columnWidths.dropLast().reduce(0, +) + columnWidths.last! - 15
            let statusIndicatorY = currentY - 20
            drawStatusIndicator(at: CGPoint(x: statusIndicatorX, y: statusIndicatorY), color: statusColor, context: context)
        }
        
        // Add sugar summary with separate fasting and after-meal averages
        if !data.isEmpty {
            let fastingReadings = data.filter { $0.type.contains("Fasting") }
            let afterMealReadings = data.filter { $0.type.contains("After") }
            
            currentY += 10
            
            if !fastingReadings.isEmpty {
                let avgFasting = fastingReadings.map { $0.value }.reduce(0, +) / fastingReadings.count
                let fastingSummary = "Average Fasting: \(avgFasting) mg/dL (\(fastingReadings.count) readings)"
                let fastingAttributes: [NSAttributedString.Key: Any] = [
                    .font: fonts.1,
                    .foregroundColor: UIColor.systemOrange
                ]
                fastingSummary.draw(at: CGPoint(x: margin, y: currentY), withAttributes: fastingAttributes)
                currentY += 20
            }
            
            if !afterMealReadings.isEmpty {
                let avgAfterMeal = afterMealReadings.map { $0.value }.reduce(0, +) / afterMealReadings.count
                let afterMealSummary = "Average After Meal: \(avgAfterMeal) mg/dL (\(afterMealReadings.count) readings)"
                let afterMealAttributes: [NSAttributedString.Key: Any] = [
                    .font: fonts.1,
                    .foregroundColor: UIColor.systemOrange
                ]
                afterMealSummary.draw(at: CGPoint(x: margin, y: currentY), withAttributes: afterMealAttributes)
                currentY += 25
            }
        }
        
        return currentY + 20
    }
    
    // Helper function to draw status indicators
    private func drawStatusIndicator(at point: CGPoint, color: UIColor, context: CGContext) {
        let radius: CGFloat = 4
        let circleRect = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
        
        context.setFillColor(color.cgColor)
        context.fillEllipse(in: circleRect)
        
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(1)
        context.strokeEllipse(in: circleRect)
    }
    
    // Enhanced date formatting
    private func formatDate(_ date: Date, style: DateStyle) -> String {
        let formatter = DateFormatter()
        switch style {
        case .compact:
            formatter.dateFormat = "MMM dd"
        case .full:
            formatter.dateFormat = "MMM dd, yyyy"
        }
        return formatter.string(from: date)
    }
    
    // Enhanced time formatting
    private func formatTime(_ time: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: time)
    }
    
    enum DateStyle {
        case compact, full
    }
    
    // MARK: - Helper Functions
    private func drawTableRow(
        columns: [String],
        widths: [CGFloat],
        at point: CGPoint,
        font: UIFont,
        textColor: UIColor,
        backgroundColor: UIColor,
        context: CGContext,
        isHeader: Bool
    ) -> CGFloat {
        let rowHeight: CGFloat = isHeader ? 35 : 30
        let cellPadding: CGFloat = 8
        let borderWidth: CGFloat = 1.0
        
        // Draw background with proper cell boundaries
        context.setFillColor(backgroundColor.cgColor)
        context.fill(CGRect(x: point.x, y: point.y, width: widths.reduce(0, +), height: rowHeight))
        
        // Draw outer border
        context.setStrokeColor(UIColor.darkGray.cgColor)
        context.setLineWidth(borderWidth)
        context.stroke(CGRect(x: point.x, y: point.y, width: widths.reduce(0, +), height: rowHeight))
        
        // Text attributes
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]
        
        var xOffset = point.x
        for (index, column) in columns.enumerated() {
            // Draw individual cell background
            let cellRect = CGRect(x: xOffset, y: point.y, width: widths[index], height: rowHeight)
            
            // Draw cell border
            context.setStrokeColor(UIColor.lightGray.cgColor)
            context.setLineWidth(0.5)
            context.stroke(cellRect)
            
            // Calculate text area with proper padding
            let textRect = CGRect(
                x: xOffset + cellPadding,
                y: point.y + (rowHeight - font.lineHeight) / 2,
                width: widths[index] - (cellPadding * 2),
                height: font.lineHeight
            )
            
            // Draw text with word wrapping if needed
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = index == 0 ? .left : .center // Left align first column, center others
            paragraphStyle.lineBreakMode = .byTruncatingTail
            
            var textAttributes = attributes
            textAttributes[.paragraphStyle] = paragraphStyle
            
            // Truncate long text to fit in cell
            let truncatedText = truncateText(column, font: font, maxWidth: textRect.width)
            truncatedText.draw(in: textRect, withAttributes: textAttributes)
            
            xOffset += widths[index]
        }
        
        return point.y + rowHeight
    }
    
    // Helper function to truncate text if it's too long
    private func truncateText(_ text: String, font: UIFont, maxWidth: CGFloat) -> String {
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let textSize = text.size(withAttributes: attributes)
        
        if textSize.width <= maxWidth {
            return text
        }
        
        // Truncate with ellipsis
        var truncated = text
        let ellipsis = "..."
        let ellipsisSize = ellipsis.size(withAttributes: attributes)
        
        while truncated.count > 0 {
            let testText = String(truncated.prefix(truncated.count - 1)) + ellipsis
            let testSize = testText.size(withAttributes: attributes)
            
            if testSize.width <= maxWidth {
                return testText
            }
            truncated = String(truncated.dropLast())
        }
        
        return ellipsis
    }
    
    private func drawSummarySection(
        at yOffset: CGFloat,
        bounds: CGRect,
        fonts: (UIFont, UIFont),
        selectedReportPeriod: String,
        currentUserSettings: UserSettings?
    ) -> CGFloat {
        var currentY = yOffset
        let margin: CGFloat = 50
        
        // Summary title
        let summaryTitle = "📊 Summary"
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: fonts.0,
            .foregroundColor: UIColor.systemPurple
        ]
        let titleSize = summaryTitle.size(withAttributes: titleAttributes)
        summaryTitle.draw(at: CGPoint(x: margin, y: currentY), withAttributes: titleAttributes)
        currentY += titleSize.height + 15
        
        // Summary stats
        let summaryStats = [
            "Overall Medicine Adherence: \(adherenceSummary())",
            "Average Blood Pressure: \(bpSummary())",
            "Average Blood Sugar: \(sugarSummary())",
            "Report Period: \(selectedReportPeriod)",
            "Total Medicines: \(currentUserSettings?.medicines?.count ?? 0)"
        ]
        
        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: fonts.1,
            .foregroundColor: UIColor.darkGray
        ]
        
        for stat in summaryStats {
            let statSize = stat.size(withAttributes: bodyAttributes)
            stat.draw(at: CGPoint(x: margin, y: currentY), withAttributes: bodyAttributes)
            currentY += statSize.height + 8
        }
        
        return currentY + 20
    }
    
    private func drawFooter(bounds: CGRect, font: UIFont, pageNumber: Int) {
        let footerText = "Generated by SMA Health Tracker - Page \(pageNumber) - \(Date().formatted(date: .abbreviated, time: .shortened))"
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.lightGray
        ]
        
        let footerSize = footerText.size(withAttributes: footerAttributes)
        let footerY = bounds.height - 30
        let footerX = (bounds.width - footerSize.width) / 2
        
        footerText.draw(at: CGPoint(x: footerX, y: footerY), withAttributes: footerAttributes)
    }
    
    private func getDateRangeForPeriod() -> [Date] {
        let calendar = Calendar.current
        let now = Date()
        let days: Int
        let startDate: Date
        
        switch selectedReportPeriod {
        case "Daily":
            return [calendar.startOfDay(for: now)]
        case "Weekly":
            days = 7
            startDate = calendar.date(byAdding: .day, value: -(days-1), to: calendar.startOfDay(for: now))!
        case "Monthly":
            days = 30
            startDate = calendar.date(byAdding: .day, value: -(days-1), to: calendar.startOfDay(for: now))!
        default:
            return [calendar.startOfDay(for: now)]
        }
        
        return stride(from: 0, to: days, by: 1).map {
            calendar.date(byAdding: .day, value: $0, to: startDate)!
        }
    }
    
    private func getStatusColor(for status: String) -> UIColor {
        switch status.lowercased() {
        case "normal", "taken":
            return UIColor.systemGreen
        case "elevated", "high", "missed":
            return UIColor.systemRed
        case "low":
            return UIColor.systemBlue
        default:
            return UIColor.darkGray
        }
    }
    
   
}

// MARK: - Data Models for Reports
struct MedicineReportRow {
    let date: Date
    let medicine: String
    let scheduleTime: Date
    let status: String
    let actualTime: Date?
}

struct BPReportRow {
    let date: Date
    let time: Date
    let systolic: Int
    let diastolic: Int
    let status: String
}

struct SugarReportRow {
    let date: Date
    let time: Date
    let type: String
    let value: Int
    let status: String
}

// MARK: - Updated HealthReportsScreen with Enhanced PDF
// Update your existing generatePDF() method to use generateEnhancedPDF()
extension HealthReportsScreen {
    private func generatePDFEnhanced() -> URL? {
        return generateEnhancedPDF()
    }
}
// MARK: - ShareSheet (For PDF Sharing)
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - ReportDataCardView (Helper View - Glassy/Gradient Effect)
struct ReportDataCardView: View {
    let value: String
    let description: String
    let iconName: String
    let tintColor: Color
    let trend: Double?

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

// MARK: - ReportDetailSection (Retained for Completeness)
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

                    Text(Date().formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                SimpleReportDataCardView(value: adherenceValue, description: "Medicine Adherence", iconName: "chart.line.uptrend.xyaxis", tintColor: .green, trend: nil)
                SimpleReportDataCardView(value: bpValue, description: "Avg Blood Pressure", iconName: "waveform.path", tintColor: .green, trend: nil)
                SimpleReportDataCardView(value: sugarValue, description: "Avg Blood Sugar", iconName: "waveform.path", tintColor: .green, trend: nil)
            }
            .padding(15)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
            .padding(.horizontal, 5)
        }
    }
}

// MARK: - SimpleReportDataCardView (Helper View for nested cards)
struct SimpleReportDataCardView: View {
    let value: String
    let description: String
    let iconName: String
    let tintColor: Color
    let trend: Double?

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

// MARK: - HealthAlertRow (Retained for Completeness)
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

// Step 1: Helper function
func getDateRange(for period: String) -> ClosedRange<Date> {
    let calendar = Calendar.current
    let now = Date()

    switch period {
    case "Daily":
        let start = calendar.startOfDay(for: now)
        let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now)!
        return start...end

    case "Weekly":
        let start = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now))!
        return start...now

    case "Monthly":
        let start = calendar.date(byAdding: .day, value: -29, to: calendar.startOfDay(for: now))!
        return start...now

    default:
        let start = calendar.startOfDay(for: now)
        let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now)!
        return start...end
    }
}


extension View {
    func snapshot(width: CGFloat, height: CGFloat) -> UIImage {
        let controller = UIHostingController(rootView: self.frame(width: width, height: height))
        let view = controller.view!

        let targetSize = CGSize(width: width, height: height)
        view.bounds = CGRect(origin: .zero, size: targetSize)
        view.backgroundColor = .white

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
    }
}
