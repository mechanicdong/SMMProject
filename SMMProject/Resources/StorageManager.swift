//
//  StorageManager.swift
//  SMMProject
//
//  Created by 이동희 on 2022/05/17.
//

import Foundation
import FirebaseStorage

//SingleTon pattern
final class StorageManager {
    
    static let shared = StorageManager()
    
    private let storage = Storage.storage().reference()
    
    /*
     /images/mechanicdong95-gmail-com_profile_picture.png
     */
    
    ///Upload picture to firebase storage and returns completion with url string to download
    public func uploadProfilePicture(with data: Data, fileName: String, completion: @escaping (Result<String, Error>) -> Void) {
        ///upload
        storage.child("images/\(fileName)").putData(data, metadata: nil, completion: { metadata, error in
            guard error == nil else {
                //failed
                print("failed to upload data to firebase for picture")
                completion(.failure(StorageError.failedToUpload))
                return
            }
            ///get file url and set userDefaults in RegisterVC, Appdelegate(GIDSignup)
            self.storage.child("images/\(fileName)").downloadURL { url, error in
                guard let url = url else {
                    print("Failed to get download url")
                    completion(.failure(StorageError.failedToGetDownloadUrl))
                    return
                }
                //if succeeding download url
                let urlString = url.absoluteString
                print("download url returned: \(urlString)")
                completion(.success(urlString))
            }
        })
    }
    
    public enum StorageError: Error {
        case failedToUpload
        case failedToGetDownloadUrl
    }
    
    public func downloadURL(for path: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let reference = storage.child(path)
        
        reference.downloadURL { url, err in
            guard let url = url, err == nil else {
                completion(.failure(StorageError.failedToGetDownloadUrl))
                return
            }
            
            completion(.success(url))
        }
    }
}
