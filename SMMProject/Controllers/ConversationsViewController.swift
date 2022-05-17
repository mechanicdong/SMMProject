//
//  ConversationsViewController.swift
//  SMMProject: means Send My Messengsers
//
//  Created by 이동희 on 2022/05/16.
//

import UIKit
import FirebaseAuth

class ConversationsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        validateAuth()
//        let logged_in = UserDefaults.standard.bool(forKey: "logged_in")
//
//        if !logged_in {
//            let vc = LoginViewController()
//            let nav = UINavigationController(rootViewController: vc)
//            nav.modalPresentationStyle = .fullScreen
//            present(nav, animated: false, completion: nil)
//        }
        //위 코드 대신 Firebase로 로그인 상태 확인
    }
    
    //MARK: Set in viewDidAppear !
    private func validateAuth() {
        if FirebaseAuth.Auth.auth().currentUser == nil {
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false, completion: nil)
        }
    }
    
}

