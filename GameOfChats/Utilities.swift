//
//  Utilities.swift
//  GameOfChats
//
//  Created by Mohammad Shayan on 5/19/20.
//  Copyright © 2020 Mohammad Shayan. All rights reserved.
//

import UIKit
import Firebase

class Utilities {
    static let shared = Utilities()
    
    var db: Firestore {
        return Firestore.firestore()
    }
}
