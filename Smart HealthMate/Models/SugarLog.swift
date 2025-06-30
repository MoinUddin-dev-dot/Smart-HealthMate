//
//  SugarLog.swift
//  Smart HealthMate
//
//  Created by Moin on 6/23/25.
//

import Foundation
import SwiftData

enum SugarType: String, Codable {
    case fasting, random, afterMeal, bedtime, postPrandial2h
}

@Model
class SugarLog {
    var user: User
    var value: Double
    var type: SugarType
    var notes: String?
    var checkedAt: Date

    init(user: User, value: Double, type: SugarType, checkedAt: Date, notes: String? = nil) {
        self.user = user
        self.value = value
        self.type = type
        self.checkedAt = checkedAt
        self.notes = notes
    }
}
