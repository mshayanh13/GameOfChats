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
    var timestamp: Double
    var text: String?
    var imageUrl: String?
    var imageHeight: Double?
    var imageWidth: Double?
    
    init(data: [String: Any]) {
        self.fromId = data["fromId"] as? String ?? ""
        self.toId = data["toId"] as? String ?? ""
        self.timestamp = data["timestamp"] as? Double ?? 0
        self.text = data["text"] as? String
        self.imageUrl = data["imageUrl"] as? String
        self.imageHeight = data["imageHeight"] as? Double
        self.imageWidth = data["imageWidth"] as? Double
    }
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.fromId == rhs.fromId &&
            lhs.toId == rhs.toId &&
            lhs.text == rhs.text &&
            lhs.timestamp == rhs.timestamp &&
            lhs.text == rhs.text &&
            lhs.imageUrl == rhs.imageUrl
    }
    
    func chatPartnerId() -> String? {
        guard let userUid = Utilities.shared.currentUser?.uid else { return nil }
        
        return fromId == userUid ? toId : fromId
    }
}
