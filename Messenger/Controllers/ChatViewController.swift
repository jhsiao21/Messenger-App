//
//  ChatViewController.swift
//  Messenger
//
//  Created by LoganMacMini on 2024/1/28.
//

import UIKit
import MessageKit
import InputBarAccessoryView //Message聊天的文字輸入框

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
        messageInputBar.delegate = self
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
        return messages[indexPath.section] //use section
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        return messages.count
    }
}

//MARK: - MessageKit聊天的文字輸入框
extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
              let selfSender = self.selfSender,
              let messageId = createMessageId() else {
            return
        }
        
        print("Sending: \(text)")
        
        let message = Message(sender: selfSender,
                              messageId: messageId,
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
    
    private func createMessageId() -> String? {
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
