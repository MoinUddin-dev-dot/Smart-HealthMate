//
//  AIInsight.swift
//  Smart HealthMate
//
//  Created by Moin on 6/23/25.
//

import Foundation
import SwiftData

enum InsightPeriod: String, Codable {
    case daily, weekly, monthly
}
enum InsightCategory: String, Codable {
    case medicationAdherence
    case bpTrend
    case sugarPattern
}

@Model
class AIInsight {
    
    var user: User
    var period: InsightPeriod
    var startDate: Date
    var endDate: Date
    var title: String
    var summary: String
    var jsonData: String

    init(user: User, period: InsightPeriod, startDate: Date, endDate: Date, title: String, summary: String, jsonData: String) {
        self.user = user
        self.period = period
        self.startDate = startDate
        self.endDate = endDate
        self.title = title
        self.summary = summary
        self.jsonData = jsonData
    }
}
