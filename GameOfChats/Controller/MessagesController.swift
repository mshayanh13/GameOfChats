//
//  ViewController.swift
//  GameOfChats
//
//  Created by Mohammad Shayan on 5/19/20.
//  Copyright © 2020 Mohammad Shayan. All rights reserved.
//

import UIKit
import Firebase

class MessagesController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .blue
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogout))
        
        let image = UIImage(named: "new_message_icon")
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(handleNewMessage))
        
        checkIfUserIsLoggedIn()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkIfUserIsLoggedIn()
    }
    
    func checkIfUserIsLoggedIn() {
        if Auth.auth().currentUser?.uid == nil {
            perform(#selector(handleLogout), with: self, afterDelay: 0)
        } else {
            let uid = Auth.auth().currentUser?.uid
            Firestore.firestore().collection("users").document(uid!).getDocument { (document, error) in
                if let error = error {
                    debugPrint(error.localizedDescription)
                } else if let document = document, document.exists, let dictionary = document.data() as? [String: String] {
                    let name = dictionary["name"]
                    self.navigationItem.title = name
                }
            }
        }
    }
    
    @objc func handleLogout() {
        
        do {
            try Auth.auth().signOut()
            Utilities.shared.currentUser = nil
        } catch let error {
            debugPrint(error.localizedDescription)
        }
        
        let loginController = LoginController()
        loginController.modalPresentationStyle = .fullScreen
        present(loginController, animated: true)
    }
    
    @objc func handleNewMessage() {
        
        let newMessageController = NewMessageController()
        let navController = UINavigationController(rootViewController: newMessageController)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
        
    }
}

