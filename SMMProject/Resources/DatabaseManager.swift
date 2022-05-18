//
//  DatabaseManager.swift
//  SMMProject
//
//  Created by 이동희 on 2022/05/16.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager {
    
    //as Singletone
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
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
        ]) { error, _ in
            guard error == nil else {
                print("failed to write to database")
                completion(false)
                return
            }
            completion(true)
        }
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
