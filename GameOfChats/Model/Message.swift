//
//  Message.swift
//  GameOfChats
//
//  Created by Mohammad Shayan on 5/21/20.
//  Copyright © 2020 Mohammad Shayan. All rights reserved.
//

import Foundation

struct Message: Equatable {
    var fromId: String
    var toId: String
    var timestamp: String
    var text: String
    
    init(data: [String: String]) {
        self.fromId = data["fromId"] ?? ""
        self.toId = data["toId"] ?? ""
        self.timestamp = data["timestamp"] ?? String(Date().timeIntervalSince1970)
        self.text = data["text"] ?? ""
    }
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.fromId == rhs.fromId &&
            lhs.toId == rhs.toId &&
            lhs.text == rhs.text &&
            lhs.timestamp == rhs.timestamp
    }
    
    func chatPartnerId() -> String? {
        guard let userUid = Utilities.shared.currentUser?.uid else { return nil }
        
        return fromId == userUid ? toId : fromId
    }
}
