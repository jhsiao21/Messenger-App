//
//  ConversationsModels.swift
//  Messenger
//
//  Created by LoganMacMini on 2024/2/3.
//

import Foundation

struct Conversation {
    let id: String
    let name: String
    let otherUserEmail: String
    let latestMessage: LatestMessage
}

struct LatestMessage {
    let date: String
    let text: String
    let isRead: Bool
}
