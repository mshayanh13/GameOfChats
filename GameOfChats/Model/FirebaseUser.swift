//
//  FirebaseUser.swift
//  GameOfChats
//
//  Created by Mohammad Shayan on 5/19/20.
//  Copyright © 2020 Mohammad Shayan. All rights reserved.
//

import Foundation

struct FirebaseUser {
    let email: String
    let name: String
    let uid: String
    let imageURL: URL?
    
    init(data: [String: String]) {
        self.email = data["email"] ?? ""
        self.name = data["name"] ?? ""
        self.uid = data["uid"] ?? ""
        self.imageURL = URL(string: data["imageURL"] ?? "")
    }
}
