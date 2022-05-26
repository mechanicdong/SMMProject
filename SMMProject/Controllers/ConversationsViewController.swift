//
//  ConversationsViewController.swift
//  SMMProject: means Send My Messengsers
//
//  Created by 이동희 on 2022/05/16.
//

import UIKit
import FirebaseAuth
import JGProgressHUD
import SnapKit

struct Conversation {
    let id: String
    let name: String
    let otuerUserEmail: String
    let latestMessage: LatestMessage
}

struct LatestMessage {
    let date: String // in DB -> String
    let text: String // = message
    let isRead: Bool
}

class ConversationsViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private var conversations = [Conversation]()

    private let tableView: UITableView = {
        let table = UITableView()
        table.isHidden = true
        table.register(ConversationTableViewCell.self, forCellReuseIdentifier: ConversationTableViewCell.identifier)
        return table
    }()
    
    private let noConversationsLabel: UILabel = {
        let label = UILabel()
        label.text = "No Conversations!"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.isHidden = true
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.text = "current time"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 21, weight: .medium)
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(didTapComposeButton))
        view.addSubview(tableView)
        view.addSubview(noConversationsLabel)
        
        view.addSubview(timeLabel)
        do {
            //METHOD : GET
            let url = URL(string: "http://swiftapi.rubypaper.co.kr:2029/practice/currentTime")
            //API 호출
            let response = try String(contentsOf: url!)
            print(response)
            DispatchQueue.main.async {
                print("timelabel changed")
                self.timeLabel.text = response
            }
        } catch let error as NSError {
            print("오류나따@!@!@(*!@)(!*@)(!*)")
            print(error.localizedDescription)
        }
        
        setUpTableView()
        fetchConversations()
        startListeningForConversations()
    }
    
    private func startListeningForConversations() {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else { return }
        print("starting conversation fetch")
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        DatabaseManager.shared.getAllConversations(for: safeEmail) { [weak self] result in
            switch result {
            case .success(let conversations):
                print("successfully got conversation models")
                guard !conversations.isEmpty else {
                    return
                }
                
                self?.conversations = conversations
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
                
            case .failure(let error):
                print("failed to get convos: \(error)")
            }
        }
    }
    
    @objc private func didTapComposeButton() {
        let vc = NewConversationViewController()
        vc.completion = { [weak self] result in
            print("*************** completion here ***************")
            print("\(result)") // ["name": "@", "email": "@"]
            self?.createNewConversation(result: result)
        }
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true, completion: nil)
    }
    
    private func createNewConversation(result: [String : String]) {
        guard let name = result["name"],
                let email = result["email"] else {
            return
        }
        let vc = ChatViewController(with: email, id: nil) //맨 처음엔 id가 없으므로
        vc.isNewConversation = true
        vc.title = name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        timeLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
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
    
    private func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func fetchConversations() {
        tableView.isHidden = false
    }
}

extension ConversationsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = conversations[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identifier, for: indexPath) as! ConversationTableViewCell
        cell.configure(with: model)
        cell.accessoryType = .disclosureIndicator //chatting room 들어가는 화살표 추가
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true) //unhighlight
        let model = conversations[indexPath.row]
        
        let vc = ChatViewController(with: model.otuerUserEmail, id: model.id)
        vc.title = model.name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
}
