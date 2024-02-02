//
//  ChatViewController.swift
//  Messenger
//
//  Created by LoganMacMini on 2024/1/28.
//

import UIKit
import MessageKit
import InputBarAccessoryView //Message聊天的文字輸入框
import SDWebImage
import AVFoundation
import AVKit
import CoreLocation.CLLocation

/*
 messages.append(Message(sender: selfSender,
                         messageId: "1",
                         sentDate: Date(),
                         kind: MessageKind.text("Hello World messages.")))
 
 messages.append(Message(sender: selfSender,
                         messageId: "2",
                         sentDate: Date(),
                         kind: MessageKind.text("This is a test message.")))
 */

struct Message: MessageType {
    public var sender: SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKind
}

extension MessageKind {
    var messageKindTypeString: String {
        switch self {
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributedText"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .linkPreview(_):
            return "linkPreview"
        case .custom(_):
            return "custom"
        }
    }
}

struct Sender: SenderType {
    public var photoURL: String
    public var senderId: String
    public var displayName: String
}

struct Media: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
}

struct Location: LocationItem {
    var location: CLLocation
    var size: CGSize
}

class ChatViewController: MessagesViewController {
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()

    public let otherUserEmail: String
    private let conversationId: String?
    public var isNewConversation = false
    
    private var messages = [Message]()
    
    private var selfSender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String,
              let name = UserDefaults.standard.value(forKey: "name") as? String else {
            return nil
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        return Sender(photoURL: "",
               senderId: safeEmail,
               displayName: name)
    }
    
    private func listeningForMessages(id: String) {
        DatabaseManager.shared.getAllMessagesForConversation(with: id) { [weak self] result in
            switch result {
            case .success(let messages):
                guard !messages.isEmpty else {
                    return
                }
                self?.messages = messages
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                }
            case .failure(let error):
                print("Failed to get messages: \(error.localizedDescription)")
            }
        }
    }
    
    private func setupInputButton() {
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside { [weak self] _ in
            self?.presentInputActionSheet()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    
    private func presentInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Media",
                                            message: "What would you like to attach?",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Photo", style: .default, handler: { [weak self] _ in
            self?.pressentPhotoInputActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: { [weak self] _ in
            self?.pressentVideoInputActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: { _ in
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Location", style: .default, handler: { [weak self] _ in
            self?.presentLocationPicker()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    private func presentLocationPicker() {
        let vc = LocationPickerViewController(coordinates: nil)
        vc.title = "Pick Location"
        vc.isPickable = true
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.completion = { [weak self] selectedCoordinates in
            guard let strongSelf = self,
                  let conversationId = strongSelf.conversationId,
                  let name = strongSelf.title,
                  let selfSender = strongSelf.selfSender
            else { return }
                                
            let latitude: Double = selectedCoordinates.latitude
            let longitude: Double = selectedCoordinates.longitude
            
            print("Location: \(latitude),\(longitude)")
            
            let location = Location(location: CLLocation(latitude: latitude, longitude: longitude),
                                 size: .zero)
            
            let message = Message(sender: selfSender,
                                  messageId: strongSelf.createUniqueId(),
                                  sentDate: Date(),
                                  kind: .location(location))
            
            DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: message) { success in
                if success {
                    print("sent location message")
                }
                else {
                    print("failed to send location message")
                }
            }
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func pressentPhotoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Photo",
                                            message: "Where would like to attach a photo from?",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { [weak self] _ in
            
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    private func pressentVideoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Video",
                                            message: "Where would like to attach a video from?",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Library", style: .default, handler: { [weak self] _ in
            
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    init(with email: String, id: String?) {
        self.otherUserEmail = email
        self.conversationId = id
        super.init(nibName: nil, bundle: nil)
        if let conversationId = conversationId {
            listeningForMessages(id: conversationId)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        setupInputButton()
    }
        
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
    }
}

extension ChatViewController : MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    
    //決定文字框出現在左邊(對方)或右邊(我)
    func currentSender() -> MessageKit.SenderType {
        if let sender = selfSender {
            return sender
        }
        
        fatalError("Self Sender is nil, email should be cached")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> MessageKit.MessageType {
        return messages[indexPath.section] //MessageKit use section per message
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else {
            return
        }
        
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            imageView.sd_setImage(with: imageUrl, completed: nil)
        default:
            break
        }
    }
}

extension ChatViewController: MessageCellDelegate {
    
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        
        let message = messages[indexPath.section]
        
        switch message.kind {
        // only care about the photo, because we want to tap it on image to watch a bigger image with full-screen image viewer
        case .photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            let vc = PhotoViewerViewController(with: imageUrl)
            self.navigationController?.pushViewController(vc, animated: true)
        case .video(let media):
            guard let videoUrl = media.url else {
                return
            }
            let vc = AVPlayerViewController()
            vc.player = AVPlayer(url: videoUrl)
            present(vc, animated: true)
        default:
            break
        }
    }
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .text(let text):
            print("tapped message: \(text)")
        case .location(let location):
            let coordinates = location.location.coordinate
            let vc = LocationPickerViewController(coordinates: coordinates)
            vc.isPickable = false
            self.navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
    
    
}

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true, completion: nil)
        guard let conversationId = conversationId,
              let name = self.title,
              let selfSender = selfSender else {
            return
        }
        
        if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage, let imageData = image.pngData() {
            let fileName = "photo_message_" + createUniqueId()
            
            // Upload image
            StorageManager.shared.uploadMessagePhoto(with: imageData, fileName: fileName) { [weak self] result in
                guard let StrongSelf = self else { return }
                switch result {
                case .success(let urlString):
                    // Ready to send Message
                    print("Uploaded message photo: \(urlString)")
                    
                    guard let url = URL(string: urlString),
                          let placeholder = UIImage(systemName: "plus") //irrelevant image, cuz placeholderImage property is not optional
                    else {
                        return
                    }
                    
                    let media = Media(url: url,
                                      image: nil,
                                      placeholderImage: placeholder,
                                      size: .zero)   //irrelevant size, cuz size property is not optional
                    
                    let message = Message(sender: selfSender,
                                          messageId: StrongSelf.createUniqueId(),
                                          sentDate: Date(),
                                          kind: .photo(media))
                    
                    DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: StrongSelf.otherUserEmail, name: name, newMessage: message) { success in
                        if success {
                            print("sent photo message")
                        }
                        else {
                            print("failed to send photo message")
                        }
                    }
                    
                case .failure(let error):
                    print("message photo upload error: \(error.localizedDescription)")
                }
            }
        }
        else if let videoUrl = info[UIImagePickerController.InfoKey.mediaURL] as? URL {
            let fileName = "video_message_" + createUniqueId()
            
            //upload video(基本上跟photo一樣)
            StorageManager.shared.uploadMessageVideo(with: videoUrl, fileName: fileName) { [weak self] result in
                guard let StrongSelf = self else { return }
                switch result {
                case .success(let urlString):
                    // Ready to send Message
                    print("Uploaded message video: \(urlString)")
                    
                    guard let url = URL(string: urlString),
                          let placeholder = UIImage(systemName: "plus") //irrelevant image, cuz placeholderImage property is not optional
                    else {
                        return
                    }
                    
                    let media = Media(url: url,
                                      image: nil,
                                      placeholderImage: placeholder,
                                      size: .zero)   //irrelevant size, cuz size property is not optional
                    
                    let message = Message(sender: selfSender,
                                          messageId: StrongSelf.createUniqueId(),
                                          sentDate: Date(),
                                          kind: .video(media))
                    
                    DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: StrongSelf.otherUserEmail, name: name, newMessage: message) { success in
                        if success {
                            print("sent photo message")
                        }
                        else {
                            print("failed to send photo message")
                        }
                    }
                    
                case .failure(let error):
                    print("message photo upload error: \(error.localizedDescription)")
                }
            }
        }
    }
}

//MARK: - MessageKit聊天的文字輸入框
extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
              let selfSender = self.selfSender else {
            return
        }
        
        print("Sending: \(text)")
        
        let message = Message(sender: selfSender,
                              messageId: createUniqueId(),
                              sentDate: Date(),
                              kind: .text(text))
        
        //Send Message
        if isNewConversation {
            //create conversation in database
            //title因為有設定為name(聊天對象)
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, name: self.title ?? "User", firstMessage: message) { [weak self] success in
                if success {
                    print("message sent")
                    self?.isNewConversation = false
                }
                else {
                    print("failed to send")
                }
            }
        }
        else {
            //append to existing conversation data
            guard let conversationId = self.conversationId, let name = self.title else {
                return
            }
            
            DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: otherUserEmail, name: name, newMessage: message) { success in
                if success {
                    print("message sent")
                }
                else {
                    print("failed to send")
                }
            }
        }
    }
    
    private func createUniqueId() -> String {
//        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
//            return nil
//        }
//        let dateString = Self.dateFormatter.string(from: Date())
//        let safeCurrentUserEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
//        
//        let newIdentifier = "\(otherUserEmail)_\(safeCurrentUserEmail)_\(dateString)"
//        print("created message id: \(newIdentifier)")
//        return newIdentifier
        
        return NSUUID().uuidString
    }
}
