//
//  ViewController.swift
//  Messenger
//
//  Created by LoganMacMini on 2024/1/25.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

final class ConversationsViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private var conversations = [Conversation]()

    private let tableView: UITableView = {
        let table = UITableView()
        table.isHidden = true   //once we have conversation then show tableview
        table.register(ConversationTableViewCell.self, forCellReuseIdentifier: ConversationTableViewCell.identifier)
        return table
    }()
    
    private let noConversationsLabel: UILabel = {
        let label = UILabel()
        label.text = "No Conversations!"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.isHidden = true   //don't wnat to show it while loading conversations
        return label
    }()
    
    private var loginObserver : NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose,
                                                            target: self,
                                                            action: #selector(didTapComposeButton))
        view.addSubview(tableView)
        view.addSubview(noConversationsLabel)
        setupTableView()
        startListeningForConversations()
        
        loginObserver = NotificationCenter.default.addObserver(forName: .didLogInNotification, object: nil, queue: .main, using: { [weak self] _ in
            guard let strongSelf = self else {
                return
            }

            strongSelf.startListeningForConversations()
        })
    }
    
    private func startListeningForConversations() {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            print("user no exists")
            return
        }
        
        // 因為每次在TabBar按其他頁籤都會觸發validateAuth() else內的post didLogInNotification，加這行是為了startListeningForConversations只近來一次，在第一次收到didLogInNotification通知後便移除didLogInNotification觀察
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        print("Starting conversation fetch...")
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        DatabaseManager.shared.getAllConversations(for: safeEmail) { [weak self] result in
            switch result {
            case .success(let conversations):
                
                guard !conversations.isEmpty else {
                    // there's no conversations, hide tableview and show label
                    self?.tableView.isHidden = true
                    self?.noConversationsLabel.isHidden = false
                    return
                }
                self?.tableView.isHidden = false
                self?.noConversationsLabel.isHidden = true
                self?.conversations = conversations
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            case .failure(let error):
                // if not able to get conversations, hide tableview and show label
                self?.noConversationsLabel.isHidden = false
                self?.tableView.isHidden = true
                self?.showUIAlert(message: "Failed to get conversations: \(error.errorDescription)")
//                print("Failed to get conversations: \(error.localizedDescription)")
            }
        }
    }
    
    @objc private func didTapComposeButton() {
        let vc = NewConversationViewController()
        vc.completion = { [weak self] targetUserData in
            guard let strongSelf = self else {
                return
            }
            
            let currentConversations = strongSelf.conversations
            
            if let targetConversation = currentConversations.first(where: {
                $0.otherUserEmail == DatabaseManager.safeEmail(emailAddress: targetUserData.email)
            }) {    //如果從現有conversations中找到想要聊天對象的email，開啟現有對話
                let vc = ChatViewController(with: targetConversation.otherUserEmail, id: targetConversation.id)
                vc.isNewConversation = false
                vc.title = targetConversation.name //title設定為name(聊天對象)
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            }
            else {
                //新聊天對象
                self?.createNewConversation(result: targetUserData)
                print("\(targetUserData)") //["name": "Logan Hsiao", "email": "logan-hsiao-jk@gmail-com"]
            }
        }
        
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true)  //開啟NewConversationViewController
    }
    
    private func createNewConversation(result: SearchResult) {
        let name = result.name
        let email = DatabaseManager.safeEmail(emailAddress: result.email)
        
        DatabaseManager.shared.conversationExists(with: email) { [weak self] exists in
            guard let strongSelf = self else { return }
            switch exists {
            case .success(let conversationId):
                let vc = ChatViewController(with: email, id: conversationId)
                vc.isNewConversation = false
                vc.title = name //title設定為name(聊天對象)
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            case .failure(_):
                let vc = ChatViewController(with: email, id: nil)
                vc.isNewConversation = true
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        noConversationsLabel.frame = CGRect(x: 10,
                                            y: (view.height - 100) / 2,
                                            width: view.width - 20,
                                            height: 100)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
                
        validateAuth() //Register後跳回此視圖時，會再次觸發viewDidAppear來執行這行
    }
    
    private func validateAuth() {
        if FirebaseAuth.Auth.auth().currentUser == nil {
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false)
        }
        else {
            //登入後發送didLogInNotification通知
            NotificationCenter.default.post(name: .didLogInNotification, object: nil)
        }
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }
}

extension ConversationsViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identifier,
                                                 for: indexPath) as! ConversationTableViewCell
        
        let model = conversations[indexPath.row]
        cell.configure(with: model)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = conversations[indexPath.row]
        openConversation(model)
    }
    
    func openConversation(_ model: Conversation) {
        let vc = ChatViewController(with: model.otherUserEmail, id: model.id)
        vc.title = model.name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // begin delete
            let conversationId = conversations[indexPath.row].id

            DatabaseManager.shared.deleteConversation(conversationId: conversationId) { [weak self] result in
                switch result {
                case .success(_):
                    //there's no need of following code, cuz tableview data source is based on observe, which is a continous observe
//                    tableView.beginUpdates()
//                    conversations.remove(at: indexPath.row)
//                    tableView.deleteRows(at: [indexPath], with: .left)
//                    tableView.endUpdates()
//                    self?.tableView.reloadData()
                    break
                case .failure(let error):
                    if let error = error as? DatabaseManager.DatabaseResponse {
                        let errMsg = "Failed to delete conversation with ID: \(conversationId), errorMsg: \(error.errorDescription)"
                        self?.showUIAlert(message: errMsg)
                    } else {
                        self?.showUIAlert(message: error.localizedDescription)
                    }
                }
            }
            
            
        }
    }
    
    
}
