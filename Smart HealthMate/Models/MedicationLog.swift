//
//  MedicationLog.swift
//  Smart HealthMate
//
//  Created by Moin on 6/23/25.
//

import Foundation
import SwiftData

@Model
class MedicationLog {
    var schedule: MedicationSchedule
    var scheduledTime: Date
    var taken: Bool = false
    var takenAt: Date?

    init(schedule: MedicationSchedule, scheduledTime: Date, taken: Bool = false, takenAt: Date? = nil) {
        self.schedule = schedule
        self.scheduledTime = scheduledTime
        self.taken = taken
        self.takenAt = takenAt
    }
}

