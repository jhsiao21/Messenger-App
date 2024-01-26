//
//  MainTabBarViewController.swift
//  Cathaybk_iOS_interview
//
//  Created by LoganMacMini on 2024/1/4.
//

import UIKit

class MainTabBarViewController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.white
                
        let Chats = UINavigationController(rootViewController: ConversationsViewController())
        let Profile = UINavigationController(rootViewController: ProfileViewController())
                
        Chats.tabBarItem.image = UIImage(systemName: "ellipsis.message")?.withRenderingMode(.automatic)
        Chats.navigationItem.title = "Chats"
        Chats.navigationBar.prefersLargeTitles = true
        
        Profile.tabBarItem.image = UIImage(systemName: "person.crop.circle")?.withRenderingMode(.automatic)
        Profile.navigationItem.title = "Profile"
        Profile.navigationBar.prefersLargeTitles = true
        

        tabBar.backgroundColor = UIColor.white
        tabBar.tintColor = .black
        tabBar.isTranslucent = true
        tabBar.shadowImage = UIImage()
        setViewControllers([Chats, Profile], animated: true)
    }
}
