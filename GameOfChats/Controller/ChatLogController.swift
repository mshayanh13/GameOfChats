//
//  ChatLogController.swift
//  GameOfChats
//
//  Created by Mohammad Shayan on 5/20/20.
//  Copyright © 2020 Mohammad Shayan. All rights reserved.
//

import UIKit
import Firebase
import MobileCoreServices
import AVFoundation

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
    
    var startingFrame: CGRect?
    var blackBackground: UIView?
    var startingImageView: UIImageView?
    
    lazy var inputTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter message..."
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.delegate = self
        return textField
    }()
    
    lazy var inputContainerView: UIView = {
        let containerView = UIView()
        containerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50)
        containerView.backgroundColor = .white
        
        let uploadImageView = UIImageView()
        uploadImageView.image = UIImage(named: "upload_image_icon")
        uploadImageView.translatesAutoresizingMaskIntoConstraints = false
        uploadImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleUploadTap)))
        uploadImageView.isUserInteractionEnabled = true
        containerView.addSubview(uploadImageView)
        uploadImageView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        uploadImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        uploadImageView.widthAnchor.constraint(equalToConstant: 44).isActive = true
        uploadImageView.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
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
        self.inputTextField.leftAnchor.constraint(equalTo: uploadImageView.rightAnchor, constant: 8).isActive = true
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        collectionView.alwaysBounceVertical = true
        collectionView.backgroundColor = .white
        collectionView.register(ChatMessageCell.self, forCellWithReuseIdentifier: cellId)
        collectionView.keyboardDismissMode = .interactive
        
        setupKeyboardObservers()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardDidShow), name: UIResponder.keyboardDidShowNotification, object: nil)
    }
    
    @objc func handleKeyboardDidShow() {
        guard messages.count > 0 else { return }
        let indexPath = IndexPath(item: messages.count-1, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
    }
    
    @objc func handleUploadTap() {
        let imagePicker = UIImagePickerController()
        
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        imagePicker.modalPresentationStyle = .fullScreen
        imagePicker.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
            
        present(imagePicker, animated: true, completion: nil)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
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
                                self.messages.sort { (m1, m2) -> Bool in
                                    let timestamp1 = m1.timestamp
                                    let timestamp2 = m2.timestamp
                                    
                                    return timestamp1 < timestamp2
                                }

                                DispatchQueue.main.async {
                                    self.collectionView.reloadData()
                                    let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
                                    self.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    @objc func handleSend() {
        guard let text = inputTextField.text, text != "" else { return }
        
        let properties = ["text": text] as [String: Any]
        sendMessage(with: properties)
        
    }
    
    private func sendMessage(with imageUrl: String, and image: UIImage) {
        
        let properties = ["imageUrl": imageUrl,
                                    "imageWidth": image.size.width,
                                    "imageHeight": image.size.height] as [String : Any]
        sendMessage(with: properties)
        
    }
    
    private func sendMessage(with properties: [String: Any]) {
        let fromId = Utilities.shared.currentUser!.uid
        let toId = user!.uid
        
        let childRef = Firestore.firestore().collection("messages").document()
        var values = ["toId": toId,
                     "fromId": fromId,
                     "timestamp": Date().timeIntervalSince1970] as [String : Any]
        properties.forEach { (key, value) in
            values[key] = value
        }
        
        
        childRef.setData(values) { (error) in
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

extension ChatLogController {
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as? ChatMessageCell else { return ChatMessageCell() }
        
        cell.chatLogController = self
        
        let message = messages[indexPath.row]
        cell.textView.text = message.text
        
        setupCell(cell, with: message)
        
        if let text = message.text {
            cell.bubbleWidthAnchor?.constant = estimateFrame(for: text).width + 32
            cell.textView.isHidden = false
        } else if message.imageUrl != nil {
            cell.bubbleWidthAnchor?.constant = 200
            cell.textView.isHidden = true
        }
        
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
        
        if let messageImageUrl = message.imageUrl {
            cell.messageImageView.loadImageUsingCacheWithUrlString(url: URL(string: messageImageUrl))
            cell.messageImageView.isHidden = false
            cell.bubbleView.backgroundColor = .clear
        } else {
            cell.messageImageView.isHidden = true
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 80
        
        let message = messages[indexPath.row]
        if let text = message.text {
            height = estimateFrame(for: text).height + 20
        } else if let imageWidth = message.imageWidth, let imageHeight = message.imageHeight {
            height = CGFloat(imageHeight / imageWidth * 200)
        }
        
        let width = UIScreen.main.bounds.width
        
        return CGSize(width: width, height: height)
    }
    
    private func estimateFrame(for text: String) -> CGRect {
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)], context: nil)
    }
}

extension ChatLogController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleSend()
        return true
    }
}

extension ChatLogController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func getVideoURL(from url: URL, with filename: String) -> URL? {
        
        do {
            let documents = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let destination = documents.appendingPathComponent(filename)
            try FileManager.default.copyItem(at: url, to: destination)
            return destination
        } catch let error {
            print(error.localizedDescription)
            return nil
        }
        
        
    }
    
    func deleteVideo(at url: URL) {
        do {
            
            try FileManager.default.removeItem(at: url)
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let filename = NSUUID().uuidString + ".mp4"
        
        if let videoUrl = info[.mediaURL] as? URL, let newUrl = getVideoURL(from: videoUrl, with: filename) {
            
            handleVideoSelected(with: newUrl, and: filename)
            
        } else {
            
            handleImageSelected(with: info)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    private func handleVideoSelected(with videoUrl: URL, and filename: String) {
        let videoRef = Storage.storage().reference().child("message_movies/\(filename)")
        let metadata = StorageMetadata()
        metadata.contentType = "video/mp4"
        
        let uploadTask = videoRef.putFile(from: videoUrl, metadata: metadata) { (metadata, error) in
            if let error = error {
                debugPrint(error.localizedDescription)
                
            } else if let _ = metadata {
                videoRef.downloadURL { (url, error) in
                    if let error = error {
                        debugPrint(error.localizedDescription)
                    } else if let url = url, let thumbnail = self.thumbnailImage(for: videoUrl) {
                        
                        self.uploadImageToFirebaseStorage(thumbnail) { (thumbnailImageUrl) in
                            let videoUrlString = url.absoluteString
                            
                            let properties = ["videoUrl": videoUrlString,
                                              "imageUrl": thumbnailImageUrl,
                                              "imageWidth": thumbnail.size.width,
                                              "imageHeight": thumbnail.size.height] as [String : Any]
                            
                            self.sendMessage(with: properties)
                        }
                        
                    }
                    
                    self.deleteVideo(at: videoUrl)
                }
            }
        }
        
        uploadTask.observe(.progress) { (snapshot) in
            if let completedUnitCount = snapshot.progress?.completedUnitCount {
                self.navigationItem.title = String(completedUnitCount)
            }
        }
        
        uploadTask.observe(.success) { (snapshot) in
            self.navigationItem.title = self.user?.name
        }
    }
    
    private func thumbnailImage(for videoUrl: URL) -> UIImage? {
        let asset = AVAsset(url: videoUrl)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        do {
            let thumbnailImage = try imageGenerator.copyCGImage(at: CMTime(value: 1, timescale: 60), actualTime: nil)
            return UIImage(cgImage: thumbnailImage)
        } catch let error {
            debugPrint(error.localizedDescription)
        }
        
        
        
        return nil
    }
    
    private func handleImageSelected(with info: [UIImagePickerController.InfoKey: Any]) {
        var selectedImage: UIImage?
        
        if let editedImage = info[.editedImage] as? UIImage {
            selectedImage = editedImage
        } else if let originalImage = info[.originalImage] as? UIImage {
            selectedImage = originalImage
        }
        
        if let selectedImage = selectedImage {
            uploadImageToFirebaseStorage(selectedImage) { (imageUrl) in
                self.sendMessage(with: imageUrl, and: selectedImage)
            }
        }
    }
    
    func uploadImageToFirebaseStorage(_ image: UIImage, completion: @escaping (_ imageUrl: String)->Void) {
        
        if let imageData = image.jpegData(compressionQuality: 0.2) {
            let profileImageRef = Storage.storage().reference().child("message_images/\(NSUUID().uuidString).jpg")
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            profileImageRef.putData(imageData, metadata: metadata) { (metadata, error) in
                if let error = error {
                    debugPrint(error.localizedDescription)
                } else if let _ = metadata {
                    profileImageRef.downloadURL { (url, error) in
                        if let url = url {
                            completion(url.absoluteString)
                        }
                        
                        
                    }
                    
                    
                }
            }
        }
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func performZoomIn(for startingImageView: UIImageView) {
        startingFrame = startingImageView.superview?.convert(startingImageView.frame, to: nil)
        self.startingImageView = startingImageView
        self.startingImageView?.isHidden = true
        
        guard let startingFrame = startingFrame, let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else { return }
        blackBackground = UIView(frame: keyWindow.frame)
        
        let zoomingImageView = UIImageView(frame: startingFrame)
        zoomingImageView.backgroundColor = .red
        zoomingImageView.image = startingImageView.image
        zoomingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomOut)))
        zoomingImageView.isUserInteractionEnabled = true
        
        if let blackBackground = blackBackground {
            
            blackBackground.backgroundColor = .black
            blackBackground.alpha = 0
            keyWindow.addSubview(blackBackground)
            
            keyWindow.addSubview(zoomingImageView)
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                blackBackground.alpha = 1
                self.inputContainerView.alpha = 0
                
                let height = startingFrame.height / startingFrame.width * keyWindow.frame.width
                
                zoomingImageView.frame = CGRect(x: 0, y: 0, width: keyWindow.frame.width, height: height)
                zoomingImageView.center = keyWindow.center
            }, completion: nil)
        
        }
    }
    
    @objc func handleZoomOut(tapGesture: UITapGestureRecognizer) {
        guard let startingFrame = startingFrame, let zoomOutImageView = tapGesture.view, let blackBackground = blackBackground else { return }
        zoomOutImageView.layer.cornerRadius = 16
        zoomOutImageView.clipsToBounds = true
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            zoomOutImageView.frame = startingFrame
            blackBackground.alpha = 0
            self.inputContainerView.alpha = 1
        }) { (completed) in
            zoomOutImageView.removeFromSuperview()
            self.startingImageView?.isHidden = false
        }
    }
}
