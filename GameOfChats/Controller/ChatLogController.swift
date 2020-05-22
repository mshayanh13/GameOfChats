//
//  ChatLogController.swift
//  GameOfChats
//
//  Created by Mohammad Shayan on 5/20/20.
//  Copyright © 2020 Mohammad Shayan. All rights reserved.
//

import UIKit
import Firebase

class ChatLogController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    let cellId = "cellId"
    var messages = [Message]()
    var user: FirebaseUser? {
        didSet {
            navigationItem.title = user?.name
            
            observeMessages()
        }
    }
    
    var containerViewBottomAnchor: NSLayoutConstraint?
    
    func observeMessages() {
        guard let currentUserUid = Utilities.shared.currentUser?.uid,
            let userUid = user?.uid else { return }
        
        let query = Firestore.firestore().collection("user-messages").document(currentUserUid).collection(userUid)
            query.addSnapshotListener { (snapshot, error) in
            if let error = error {
                debugPrint(error.localizedDescription)
            } else if let snapshot = snapshot {
                let documents = snapshot.documentChanges
                for document in documents {
                    let messageId = document.document.data().keys.first!
                    
                    Firestore.firestore().collection("messages").document(messageId).getDocument { (snapshot, error) in
                        if let error = error {
                            debugPrint(error.localizedDescription)
                        } else if let snapshot = snapshot, let dictionary = snapshot.data() {
                            let message = Message(data: dictionary)
                            if !self.messages.contains(message) && message.chatPartnerId() == self.user?.uid {
                                self.messages.append(message)

                                DispatchQueue.main.async {
                                    self.collectionView.reloadData()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    lazy var inputTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter message..."
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.delegate = self
        return textField
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        //collectionView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        collectionView.alwaysBounceVertical = true
        collectionView.backgroundColor = .white
        collectionView.register(ChatMessageCell.self, forCellWithReuseIdentifier: cellId)
        collectionView.keyboardDismissMode = .interactive
        //setupInputComponents()
        //setupKeyboardObservers()
    }
    
    lazy var inputContainerView: UIView = {
        let containerView = UIView()
        containerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50)
        containerView.backgroundColor = .white
        
        let sendButton = UIButton(type: .system)
        sendButton.setTitle("Send", for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        containerView.addSubview(sendButton)
        sendButton.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        sendButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        
        containerView.addSubview(self.inputTextField)
        self.inputTextField.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 8).isActive = true
        self.inputTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        self.inputTextField.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        self.inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor, constant: 8).isActive = true
        
        let separatorLineView = UIView()
        separatorLineView.backgroundColor = .black
        separatorLineView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(separatorLineView)
        separatorLineView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        separatorLineView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        separatorLineView.widthAnchor.constraint(equalTo: containerView.widthAnchor).isActive = true
        separatorLineView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        return containerView
    }()
    
    override var inputAccessoryView: UIView? {
        get {
            return inputContainerView
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func handleKeyboardWillShow(notification: Notification) {
        if let keyboardHeight = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as AnyObject).cgRectValue?.height, let keyboardDuration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue {
            containerViewBottomAnchor?.constant = -keyboardHeight
            UIView.animate(withDuration: keyboardDuration) {
                self.view.layoutIfNeeded()
            }
        }
        
    }
    
    @objc func handleKeyboardWillHide(notification: Notification) {
        containerViewBottomAnchor?.constant = 0
        
        if let keyboardDuration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue {
        
            UIView.animate(withDuration: keyboardDuration) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as? ChatMessageCell else { return ChatMessageCell() }
        let message = messages[indexPath.row]
        cell.textView.text = message.text
        
        setupCell(cell, with: message)
        
        cell.bubbleWidthAnchor?.constant = estimateFrame(for: message.text).width + 32
        
        return cell
    }
    
    private func setupCell(_ cell: ChatMessageCell, with message: Message) {
        cell.profileImageView.loadImageUsingCacheWithUrlString(url: self.user?.imageURL)
        
        if message.fromId == Utilities.shared.currentUser?.uid {
            cell.bubbleView.backgroundColor = ChatMessageCell.blueColor
            cell.textView.textColor = .white
            cell.bubbleViewRightAnchor?.isActive = true
            cell.bubbleViewLeftAnchor?.isActive = false
            cell.profileImageView.isHidden = true
        } else {
            cell.bubbleView.backgroundColor = UIColor(r: 240, g: 240, b: 240)
            cell.textView.textColor = .black
            cell.bubbleViewRightAnchor?.isActive = false
            cell.bubbleViewLeftAnchor?.isActive = true
            cell.profileImageView.isHidden = false
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 80
        height = estimateFrame(for: messages[indexPath.row].text).height + 20
        
        let width = UIScreen.main.bounds.width
        
        return CGSize(width: width, height: height)
    }
    
    private func estimateFrame(for text: String) -> CGRect {
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)], context: nil)
    }
    
    func setupInputComponents() {
        let containerView = UIView()
        containerView.backgroundColor = .white
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(containerView)
        
        containerView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        containerViewBottomAnchor = containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        containerViewBottomAnchor?.isActive = true
        containerView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        containerView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        let sendButton = UIButton(type: .system)
        sendButton.setTitle("Send", for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        containerView.addSubview(sendButton)
        sendButton.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        sendButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        
        containerView.addSubview(inputTextField)
        inputTextField.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 8).isActive = true
        inputTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        inputTextField.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor, constant: 8).isActive = true
        
        let separatorLineView = UIView()
        separatorLineView.backgroundColor = .black
        separatorLineView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(separatorLineView)
        separatorLineView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        separatorLineView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        separatorLineView.widthAnchor.constraint(equalTo: containerView.widthAnchor).isActive = true
        separatorLineView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
    }
    
    @objc func handleSend() {
        guard let text = inputTextField.text, text != "" else { return }
        
        let fromId = Utilities.shared.currentUser!.uid
        let toId = user!.uid
        
        let childRef = Firestore.firestore().collection("messages").document()
        let value = ["text": text,
                     "toId": toId,
                     "fromId": fromId,
                     "timestamp": Date().timeIntervalSince1970] as [String : Any]
        childRef.setData(value) { (error) in
            if let error = error {
                debugPrint(error.localizedDescription)
            } else {
                
                self.inputTextField.text = nil
                let messageId = childRef.documentID
                
                let fromUserMessagesRef = Firestore.firestore().collection("user-messages").document(fromId).collection(toId).document()
                fromUserMessagesRef.setData([messageId: 1], merge: true)
                
                let toUserMessagesRef = Firestore.firestore().collection("user-messages").document(toId).collection(fromId).document()
                toUserMessagesRef.setData([messageId: 1], merge: true)
                
                let fromUserMessagesRecentRef = Firestore.firestore().collection("user-messages").document(fromId).collection("recent").document(toId)
                fromUserMessagesRecentRef.setData([messageId: 1])
                
                let toUserMessagesRecentRef = Firestore.firestore().collection("user-messages").document(toId).collection("recent").document(fromId)
                toUserMessagesRecentRef.setData([messageId: 1])
            }
        }
        
    }
}

extension ChatLogController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleSend()
        return true
    }
}
