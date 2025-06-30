//
//  User.swift
//  Smart HealthMate
//
//  Created by Moin on 6/23/25.
//

import Foundation
import SwiftData

@Model
class User {
    @Attribute(.unique) var email: String
    var name : String
    var createdAt: Date

    // Relationships
    @Relationship var medications: [Medication] = []
    @Relationship var bpLogs: [BPLog] = []
    @Relationship var sugarLogs: [SugarLog] = []
    @Relationship var insights: [AIInsight] = []
    @Relationship var messages: [ChatMessage] = []

    init(email: String, name: String, createdAt: Date = .now) {
        self.email = email
        self.name = name
        self.createdAt = createdAt
    }
}

