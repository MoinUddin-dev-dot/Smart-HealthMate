//
//  ChatMessage.swift
//  Smart HealthMate
//
//  Created by Moin on 6/23/25.
//

import Foundation
import SwiftData

enum MessageSender: String, Codable {
    case user, bot
}

@Model
class ChatMessage {
    var user: User
    var message: String
    var sender: MessageSender
    var timestamp: Date

    init(user: User, message: String, sender: MessageSender, timestamp: Date = .now) {
        self.user = user
        self.message = message
        self.sender = sender
        self.timestamp = timestamp
    }
}
