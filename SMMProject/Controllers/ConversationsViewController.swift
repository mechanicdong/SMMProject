//
//  ConversationsViewController.swift
//  SMMProject: means Send My Messengsers
//
//  Created by 이동희 on 2022/05/16.
//

import UIKit

class ConversationsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor =  .red
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let logged_in = UserDefaults.standard.bool(forKey: "logged_in")
        
        if !logged_in {
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false, completion: nil)
        }
    }
    
    
}

