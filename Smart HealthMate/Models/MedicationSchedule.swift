//
//  MedicationSchedule.swift
//  Smart HealthMate
//
//  Created by Moin on 6/23/25.
//

import Foundation
import SwiftData

@Model
class MedicationSchedule {
    
    var medication: Medication

    var time: Date
    var dosageInstruction: String
    var isActive: Bool = true

    @Relationship(deleteRule: .cascade, inverse: \MedicationLog.schedule)
    var logs: [MedicationLog] = []

    init(medication: Medication, time: Date, dosageInstruction: String) {
        self.medication = medication
        self.time = time
        self.dosageInstruction = dosageInstruction
    }
}

