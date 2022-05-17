//
//  ChatViewController.swift
//  SMMProject
//
//  Created by 이동희 on 2022/05/17.
//

import UIKit
import MessageKit

//for messages
struct Message: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind //text, photo, video, locaion, contact so on
}

//for sender
struct Sender: SenderType {
    var photoURL: String //added
    var senderId: String
    var displayName: String
}

class ChatViewController: MessagesViewController {

    private var messages = [Message]()
    
    private let selfSender = Sender(photoURL: "",
                                     senderId: "1",
                                     displayName: "Joe Smith")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messages.append(Message(sender: selfSender,
                                messageId: "1",
                                sentDate: Date(), //current date
                                kind: .text("Hello World message")))
        
        messages.append(Message(sender: selfSender,
                                messageId: "1",
                                sentDate: Date(), //current date
                                kind: .text("Hello World message")))
        
        messages.append(Message(sender: selfSender,
                                messageId: "1",
                                sentDate: Date(), //current date
                                kind: .text("Hello World message, long type message!")))
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
    }

}

extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    func currentSender() -> SenderType {
        return selfSender
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }

}
