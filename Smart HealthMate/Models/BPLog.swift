//
//  BPLog.swift
//  Smart HealthMate
//
//  Created by Moin on 6/23/25.
//

import Foundation
import SwiftData

@Model
class BPLog {
    var user: User
    var systolic: Int
    var diastolic: Int
    var pulse: Int?
    var notes: String?
    var checkedAt: Date

    init(user: User, systolic: Int, diastolic: Int, checkedAt: Date, pulse: Int? = nil, notes: String? = nil) {
        self.user = user
        self.systolic = systolic
        self.diastolic = diastolic
        self.checkedAt = checkedAt
        self.pulse = pulse
        self.notes = notes
    }
}
