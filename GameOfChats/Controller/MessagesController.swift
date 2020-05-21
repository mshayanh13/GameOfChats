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

    let cellId = "cellId"
    var messages = [Message]()
    var messagesDictionary = [String: Message]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogout))
        
        let image = UIImage(named: "new_message_icon")
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(handleNewMessage))
        
        checkIfUserIsLoggedIn()
        
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
    }
    
    func observeUserMessages() {
        guard let userUid = Utilities.shared.currentUser?.uid else { return }
        Firestore.firestore().collection("user-messages").document(userUid).addSnapshotListener { (snapshot, error) in
            if let error = error {
                debugPrint(error.localizedDescription)
            } else if let snapshot = snapshot, let messagesDictionary = snapshot.data() {
                
                for key in messagesDictionary.keys {
                    Firestore.firestore().collection("messages").document(key).getDocument { (snapshot, error) in
                        if let error = error {
                            debugPrint(error.localizedDescription)
                        } else if let snapshot = snapshot, let messageDictionary = snapshot.data() as? [String: String] {
                            
                            let message = Message(data: messageDictionary)
                            
                            if let chatPartnerId = message.chatPartnerId() {
                                if !self.messages.contains(message) {
                                    
                                    if let previousMessage =  self.messagesDictionary[chatPartnerId] {
                                        if previousMessage.timestamp < message.timestamp {
                                            self.messagesDictionary[chatPartnerId] = message
                                        }
                                    } else {
                                        self.messagesDictionary[chatPartnerId] = message
                                    }
                                    
                                    self.messages = Array(self.messagesDictionary.values)
                                    self.messages.sort { (m1, m2) -> Bool in
                                        if let timestamp1 = Double(m1.timestamp), let timestamp2 = Double(m2.timestamp) {
                                            return timestamp1 > timestamp2
                                        } else {
                                            return false
                                        }
                                    }
                                }
                            }
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                            }
                        }
                    }
                }
            }
        }
    }
    
    func observeMessages() {
        Firestore.firestore().collection("messages").addSnapshotListener { (snapshot, error) in
            if let error = error {
                debugPrint(error.localizedDescription)
            } else if let snapshot = snapshot {
                for documentChange in snapshot.documentChanges {
                    if let document = documentChange.document.data() as? [String: String] {
                        let message = Message(data: document)
                        if !self.messages.contains(message) {
                            
                            self.messagesDictionary[message.toId] = message
                            self.messages = Array(self.messagesDictionary.values)
                            self.messages.sort { (m1, m2) -> Bool in
                                if let timestamp1 = Double(m1.timestamp), let timestamp2 = Double(m2.timestamp) {
                                    return timestamp1 > timestamp2
                                } else {
                                    return false
                                }
                            }
                        }
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                        
                        
                    }
                    
                }
            }
        }
    }
    
    func checkIfUserIsLoggedIn() {
        if Auth.auth().currentUser?.uid == nil {
            perform(#selector(handleLogout), with: self, afterDelay: 0)
        } else {
            fetchUserAndSetupNavBarTitle()
        }
    }
    
    func fetchUserAndSetupNavBarTitle() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Utilities.shared.currentUser = Auth.auth().currentUser
        
        Firestore.firestore().collection("users").document(uid).getDocument { (document, error) in
            if let error = error {
                debugPrint(error.localizedDescription)
            } else if let document = document, document.exists, let dictionary = document.data() as? [String: String] {
                                
                let user = FirebaseUser(data: dictionary)
                self.setupNavBarWithUser(user: user)
            }
        }
    }
    
    func setupNavBarWithUser(user: FirebaseUser) {
        
        messagesDictionary.removeAll()
        messages.removeAll()
        
        tableView.reloadData()
        
        observeUserMessages()
        
        let titleView: UIView = {
            let view = UIView()
            
            view.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
            
            return view
        }()
        
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        titleView.addSubview(containerView)
        
        let profileImageView = UIImageView()
        profileImageView.loadImageUsingCacheWithUrlString(url: user.imageURL)
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 20
        
        containerView.addSubview(profileImageView)
        
        profileImageView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        let nameLabel = UILabel()
        nameLabel.text = user.name
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(nameLabel)
        
        nameLabel.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8).isActive = true
        nameLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        nameLabel.heightAnchor.constraint(equalTo: profileImageView.heightAnchor).isActive = true
        
        containerView.centerXAnchor.constraint(equalTo: titleView.centerXAnchor).isActive = true
        containerView.centerYAnchor.constraint(equalTo: titleView.centerYAnchor).isActive = true
        
        self.navigationItem.titleView = titleView
        
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? UserCell else { return UserCell() }
        let message = messages[indexPath.row]
        cell.message = message
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let message = messages[indexPath.row]
        guard let chatPartnerId = message.chatPartnerId() else {
            return
        }
        
        Firestore.firestore().collection("users").document(chatPartnerId).getDocument { (snapshot, error) in
            if let error = error {
                debugPrint(error.localizedDescription)
            } else if let snapshot = snapshot {
                guard var dictionary = snapshot.data() as? [String: String] else { return }
                
                dictionary["id"] = chatPartnerId
                let user = FirebaseUser(data: dictionary)
                
                self.showChatController(for: user)
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
        loginController.messagesController = self
        present(loginController, animated: true)
    }
    
    @objc func handleNewMessage() {
        
        let newMessageController = NewMessageController()
        newMessageController.messagesController = self
        let navController = UINavigationController(rootViewController: newMessageController)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
        
    }
    
    func showChatController(for user: FirebaseUser) {
        let chatLogController = ChatLogController(collectionViewLayout: UICollectionViewFlowLayout())
        chatLogController.user = user
        chatLogController.modalPresentationStyle = .fullScreen
        navigationController?.pushViewController(chatLogController, animated: true)
    }
}
