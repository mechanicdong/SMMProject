//
//  DatabaseManager.swift
//  SMMProject
//
//  Created by 이동희 on 2022/05/16.
//

import Foundation
import FirebaseDatabase
import InputBarAccessoryView

final class DatabaseManager {
    
    //as Singleton
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    static func safeEmail(emailAddress: String) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
}

//MARK: Account Management, write function to database
extension DatabaseManager {
    
    ///check validate new user with email
    public func userExists(with email: String, completion: @escaping ((Bool) -> Void)) {
        
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        database.child(safeEmail).observeSingleEvent(of: .value) { snapshot in
            guard snapshot.value as? String != nil else {
                completion(false) //email not exist
                return
            }
            completion(true) //exist same email -> can't create new user
        }
    }
    
    ///Inserts new user to database
    public func insertUser(with user: ChatAppUser, completion: @escaping (Bool) -> Void) {
        //MARK: KEY = emailAddress(Unique)
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName
        ], withCompletionBlock: { error, _ in
            guard error == nil else {
                print("failed to write to database")
                completion(false)
                return
            }
            

            
            self.database.child("users").observeSingleEvent(of: .value, with:  { snapshot in
                if var usersCollection = snapshot.value as? [[String : String]] {
                    //append to user dictionary
                    let newElement =  [
                        "name": user.firstName + " " + user.lastName,
                        "email": user.safeEmail
                    ]
                    usersCollection.append(newElement)
                    
                    self.database.child("users").setValue(usersCollection) { err, _ in
                        guard err == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                }
                else {
                    //create that array
                    let newCollection: [[String : String]] = [
                        [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.safeEmail
                        ]
                    ]
                    
                    self.database.child("users").setValue(newCollection) { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                    }
                    completion(true)
                }
            })
        })
    }
    
    public func getAllUsers(completion: @escaping (Result<[[String : String]], Error>) -> Void) {
        database.child("users").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value as? [[String : String]] else {
                completion(.failure(DatabaseErrors.failedToFetch))
                return
            }
            
            completion(.success(value))
        }
    }
    
    public enum DatabaseErrors: Error {
        case failedToFetch
    }
    
    /*
     users =>
     [
        [
            "name":
            "safe_email":
        ],
        [
            "name":
            "safe_email":
        ],
     ]
     */
    
}

// MARK: - Sending messages / conversations
extension DatabaseManager {
    
    /*
     "dfsdfsdfs" {
        "messages": [
            {
                "id": String,
                "type": text, photo, video,
                "content": variety(text,photourl...),
                "date": Date(),
                "sender_email": String,
                "isRead": true/false
            }
        ]
     }
     
     conversation(collection) => [
        [
            "conversation_id": "dfsdfsdfs"(unique) ===> "id"
            "other_user_email":
            "latest_message": => {
                "date": Date()
                "latest_message": "message"
                "is_read": true/false
            }
        ],
     ]
     */
    
    /// Creates a new conversation with targer user email and first message sent
    public func createNewConversation(with otherUserEmail: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else { return }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        
        let ref = database.child(safeEmail)
        ref.observeSingleEvent(of: .value) { snapshot in
            guard var userNode = snapshot.value as? [String: Any] else {
                completion(false)
                print("user not found")
                return
            }
            
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            
            switch firstMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            let conversationId = "conversation_\(firstMessage.messageId)"
            
            let newConversationData: [String: Any] = [
                "id": conversationId,
                "other_user_email": otherUserEmail,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ],
            ]
            
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                // conversation array exists for current user
                // you should append
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                ref.setValue(userNode) { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(conversationID: conversationId, firstMessage: firstMessage,  completion: completion)
                }
            }
            else {
                // conversation array does not exist
                // should create it
                userNode["conversations"] = [
                    newConversationData
                ]
                
                // input to the database
                ref.setValue(userNode) { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    
                    self?.finishCreatingConversation(conversationID: conversationId, firstMessage: firstMessage,  completion: completion)
                }
            }
        }
    }
    
    private func finishCreatingConversation(conversationID: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
//        {
//            "id": String,
//            "type": text, photo, video,
//            "content": variety(text,photourl...),
//            "date": Date(),
//            "sender_email": String,
//            "isRead": true/false
//        }
        
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        var message = ""
        
        switch firstMessage.kind {
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        let collectionMessage: [String: Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": message,
            "date": dateString,
            "sender_email": currentUserEmail,
            "is_read": false
        ]
        
        let value: [String: Any] = [
            "messages": [
                collectionMessage
            ]
        ]
        
        print("adding conversation: \(conversationID)")
        database.child("\(conversationID)").setValue(value) { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        }
    }

    
    /// Fetches and returns all conversations for the user with passed in email
    public func getAllConversations(for email: String, completion: @escaping (Result<String, Error>) -> Void) {
        
    }
    
    /// Gets all messages for a given conversation
    public func getAllMessagesForConversations(with id: String, completion: @escaping (Result<String, Error>) -> Void) {
        
    }
    
    /// Sends a message with target conversation and message
    public func sendMessage(to conversation: String, message: Message, completion: @escaping (Bool) -> Void) {
        
    }
}







struct ChatAppUser {
    let firstName: String
    let lastName: String
    let emailAddress: String
    var profilePictureFileName: String {
        //mechanicdong95-gmail-com_profile_picture.png
        return "\(safeEmail)_profile_picture.png"
    }
    
    var safeEmail: String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
}

