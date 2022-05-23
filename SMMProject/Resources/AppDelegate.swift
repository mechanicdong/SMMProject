//
//  AppDelegate.swift
//  SMMProject
//
//  Created by 이동희 on 2022/05/16.
//

import UIKit
import Firebase
import GoogleSignIn
import FirebaseMessaging
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
                
        Messaging.messaging().delegate = self
        
        //FCM 현재 등록 토큰 확인
        Messaging.messaging().token { token, error in
            if let error = error {
                print("ERROR FCM 등록토큰 가져오기: \(error)")
            }
            else if let token = token {
                print("FCM 등록토큰: \(token)")
            }
        }
        
        UNUserNotificationCenter.current().delegate = self
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { success, error in
            guard success else { return }
            print("success in APNs registry")
        }
        
        application.registerForRemoteNotifications()
        
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
        
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.list, .banner, .badge, .sound])
    }
    
    //FCM 등록 토큰 갱신
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        messaging.token { token, _ in
            guard let token = token else { return }
            
            print("FCM 등록 토큰 갱신: \(token)")
        }
    }
    
    

    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {

        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {

    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        guard error == nil else {
            if let error = error {
                print("Failed to sign in with Google: \(error)")
            }
            return
        }
        
        guard let user = user else { return }
        print("Did sign in with Google: \(user)")
        
        guard let email = user.profile.email,
              let firstName = user.profile.givenName,
              let lastName = user.profile.familyName else { return }
        
        UserDefaults.standard.set(email, forKey: "email")
        
        //Realtime DB에 동일 이메일이 가입되어 있는지 확인
        DatabaseManager.shared.userExists(with: email) { exists in
            if !exists { //user does not exist
                //insert to database
                let chatUser = ChatAppUser(firstName: firstName, lastName: lastName, emailAddress: email)
                DatabaseManager.shared.insertUser(with: chatUser) { success in
                    if success {
                        //upload google account's customed profile
                        if user.profile.hasImage {
                            guard let url = user.profile.imageURL(withDimension: 200) else {
                                return
                            }
                            
                            URLSession.shared.dataTask(with: url) { data, _, _ in
                                guard let data = data else {
                                    return
                                }
                                let fileName = chatUser.profilePictureFileName
                                StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName) { result in
                                    switch result {
                                    case .success(let downloadUrl):
                                        UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                        print(downloadUrl)
                                    case .failure(let error):
                                        print("Storage manager error: \(error)")
                                    }
                                }  
                            }.resume()
                        }
                    } // end of success
                }
            }
        }
        
        guard let authentication = user.authentication,
              let idToken = authentication.idToken else {
            print("Missing auth object off of google user")
            return
        }
        
        let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                       accessToken: authentication.accessToken)
        FirebaseAuth.Auth.auth().signIn(with: credential) { authResult, error in
            guard authResult != nil, error == nil else {
                print("failed to log in with google credential")
                return
            }
            print("Successfully signed in with Google Cred.")
            //Post to Observer
            NotificationCenter.default.post(name: .didLogInNotification, object: nil)
        }
    }

    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
         print("Google user was disconnected")
    }
    
    func application(_ application: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
      return GIDSignIn.sharedInstance().handle(url)
    }
}


