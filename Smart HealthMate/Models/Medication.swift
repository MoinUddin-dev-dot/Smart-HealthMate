//
//  Medication.swift
//  Smart HealthMate
//
//  Created by Moin on 6/23/25.
//

import Foundation
import SwiftData

@Model
class Medication {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    var purpose: String
    var durationDays: Int
    var startDate: Date
    var user: User?
    
    @Relationship( deleteRule: .cascade, inverse: \MedicationSchedule.medication) var schedules: [MedicationSchedule] = []
    
    init(name: String, purpose: String, durationDays: Int, startDate: Date, user: User? = nil) {
        self.name = name
        self.purpose = purpose
        self.durationDays = durationDays
        self.startDate = startDate
        self.user = user
    }
}
