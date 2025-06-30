////
////  MedicineDetailCardView.swift
////  Smart HealthMate
////
////  Created by Moin on 6/18/25.
////

import SwiftUI

// MedicineDetailCardView (No Change)
struct MedicineDetailCardView: View {
    let medicine: Medicine
    var onTakenStatusChanged: ((_ medicineId: UUID, _ doseId: UUID, _ newIsTakenStatus: Bool) -> Void)?

    @State private var internalScheduledDoses: [Medicine.ScheduledDose]

    init(medicine: Medicine, onTakenStatusChanged: ((_ medicineId: UUID, _ doseId: UUID, _ newIsTakenStatus: Bool) -> Void)? = nil) {
        self.medicine = medicine
        _internalScheduledDoses = State(initialValue: medicine.scheduledDoses)
        self.onTakenStatusChanged = onTakenStatusChanged
    }

    private func isDoseMissed(dose: Medicine.ScheduledDose) -> Bool {
        let now = Date()
        let calendar = Calendar.current
        return calendar.compare(dose.time, to: now, toGranularity: .minute) == .orderedAscending && !dose.isTaken
    }

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(Color.blue)
                .frame(width: 6)
                .cornerRadius(12, corners: [.topLeft, .bottomLeft])

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    Image(systemName: "pill.fill")
                        .font(.title2)
                        .foregroundColor(Color.blue)
                        .frame(width: 40, height: 40)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)

                    VStack(alignment: .leading) {
                        Text(medicine.name)
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Text(medicine.dosage)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        print("Delete \(medicine.name)")
                    }) {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.red)
                            .font(.title2)
                    }
                }
                .padding(.bottom, 5)

                Text(medicine.purpose)
                    .font(.footnote)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(5)

                HStack(spacing: 5) {
                    Image(systemName: "clock.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(medicine.displayTimingFrequency)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 5)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Scheduled Doses:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    ForEach($internalScheduledDoses) { $dose in
                        HStack {
                            Text(dose.time, style: .time)
                                .font(.subheadline)
                                .foregroundColor(isDoseMissed(dose: dose) ? .red : .primary)

                            Spacer()

                            if dose.isTaken {
                                HStack(spacing: 5) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.subheadline)
                                    Text("Taken")
                                        .font(.subheadline)
                                        .foregroundColor(.green)
                                }
                            } else if isDoseMissed(dose: dose) {
                                HStack(spacing: 5) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                        .font(.subheadline)
                                    Text("Missed")
                                        .font(.subheadline)
                                        .foregroundColor(.red)
                                }
                            } else {
                                HStack(spacing: 5) {
                                    Image(systemName: "hourglass")
                                        .foregroundColor(.orange)
                                        .font(.subheadline)
                                    Text("Pending")
                                        .font(.subheadline)
                                        .foregroundColor(.orange)
                                }
                            }

                            Button(action: {
                                dose.isTaken.toggle()
                                onTakenStatusChanged?(medicine.id, dose.id, dose.isTaken)
                            }) {
                                Text(dose.isTaken ? "Untake" : "Mark Taken")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(dose.isTaken ? Color.orange : Color.blue)
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
                .padding(.bottom, 10)
            }
            .padding()
            .background(Color.white)
        }
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
//        .padding(.horizontal)
        .onChange(of: medicine.scheduledDoses) { newDoses in
             internalScheduledDoses = newDoses
         }
    }
}

// MARK: - Medicine Struct (Data model for MedicineListView)
struct Medicine: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var purpose: String
    var dosage: String
    var timingString: String
    var scheduledDoses: [ScheduledDose]

    struct ScheduledDose: Identifiable, Equatable {
        let id = UUID()
        let time: Date
        var isTaken: Bool
        init(time: Date, isTaken: Bool = false) {
            self.time = time
            self.isTaken = isTaken
        }
    }

    init(name: String, purpose: String, dosage: String, timingString: String) {
        self.name = name
        self.purpose = purpose
        self.dosage = dosage
        self.timingString = timingString

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        self.scheduledDoses = timingString.split(separator: ",")
            .compactMap { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .compactMap { timeString in
                var calendar = Calendar.current
                if let parsedTime = formatter.date(from: timeString) {
                    let timeComponents = calendar.dateComponents([.hour, .minute], from: parsedTime)
                    if let todayAtTime = calendar.date(bySettingHour: timeComponents.hour!, minute: timeComponents.minute!, second: 0, of: Date()) {
                        return ScheduledDose(time: todayAtTime, isTaken: false)
                    }
                }
                return nil
            }
            .sorted { $0.time < $1.time }
    }

    var hasMissedDoseToday: Bool {
        let now = Date()
        return scheduledDoses.contains { dose in
            let calendar = Calendar.current
            return calendar.compare(dose.time, to: now, toGranularity: .minute) == .orderedAscending && !dose.isTaken
        }
    }

    var displayTimingFrequency: String {
        if scheduledDoses.count > 1 {
            return "\(scheduledDoses.count) Times Daily"
        } else if scheduledDoses.count == 1 {
            return "Once Daily"
        }
        return "No Timing"
    }
}

#Preview {
    MedicineDetailCardView(medicine: Medicine(name: "Amlodipine", purpose: "Blood Pressure Control", dosage: "5mg", timingString: "9:00 AM, 9:00 PM"))
        .padding()
}
