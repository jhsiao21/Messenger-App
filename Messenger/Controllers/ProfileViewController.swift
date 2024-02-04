//
//  ProfileViewController.swift
//  Messenger
//
//  Created by LoganMacMini on 2024/1/25.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import SDWebImage

final class ProfileViewController: UIViewController {
    
    var imageView: UIImageView?
    
    var data = [ProfileViewModel]()
    
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.register(ProfileTableViewCell.self, forCellReuseIdentifier: ProfileTableViewCell.identifier)
        table.translatesAutoresizingMaskIntoConstraints = false
        
        return table
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        data.append(ProfileViewModel(viewModelType: .info,
                                     title: "Name: \(UserDefaults.standard.value(forKey: "name") as? String ?? "No Name")",
                                     handler: nil))
        data.append(ProfileViewModel(viewModelType: .info,
                                     title: "Email: \(UserDefaults.standard.value(forKey: "email") as? String ?? "No Email")",
                                     handler: nil))
        data.append(ProfileViewModel(viewModelType: .logout, title: "Log Out", handler: { [weak self] in
            
            guard let strongSelf = self else { return }
            
            let actionSheet = UIAlertController(title: "Confirm",
                                                message: "",
                                                preferredStyle: .actionSheet)
            actionSheet.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { [weak self] _ in
                
                guard let strongSelf = self else { return }
                
                // remove name and email from UserDefault
                UserDefaults.standard.setValue(nil, forKey: "name")
                UserDefaults.standard.setValue(nil, forKey: "email")
                
                // Facebook log out
                FBSDKLoginKit.LoginManager().logOut()
                
                // Google log out
                GIDSignIn.sharedInstance.signOut()
                
                do {
                    try FirebaseAuth.Auth.auth().signOut()
                    
                    let vc = LoginViewController()
                    let nav = UINavigationController(rootViewController: vc)
                    nav.modalPresentationStyle = .fullScreen
                    strongSelf.present(nav, animated: true)
                }
                catch {
                    print("Failed to log out")
                }
            }))
            
            actionSheet.addAction(UIAlertAction(title: "Cancel",
                                                style: .cancel,
                                                handler: nil))
            
            strongSelf.present(actionSheet, animated: true)
        }))
        
        layout()
        tableViewSetup()
        
        
    }
    
    private func tableViewSetup() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = createTableHeader()
    }
    
    private func createTableHeader() -> UIView? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        let fileName = safeEmail + "_profile_picture.png"
        let path = "images/\(fileName)"
        
        let headerView = UIView(frame: CGRect(x: 0,
                                              y: 0,
                                              width: view.width,
                                              height: 300))
        
        headerView.backgroundColor = .link
        
        let imageView = UIImageView(frame: CGRect(x: (headerView.width - 150) / 2,
                                                  y: 75,
                                                  width: 150,
                                                  height: 150))
        
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .systemBackground
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 3
        imageView.layer.cornerRadius = imageView.width / 2
        imageView.layer.masksToBounds = true
        let gesture = UITapGestureRecognizer(target: self,
                                             action: #selector(didTapChangeProfilePicture))
        imageView.addGestureRecognizer(gesture)
        imageView.isUserInteractionEnabled = true
        self.imageView = imageView
                
        headerView.addSubview(imageView)
        
        StorageManager.shared.downloadURL(for: path) { result in
            switch result {
            case .success(let url):
                imageView.sd_setImage(with: url, completed: nil)
            case .failure(let failure):
                print("Failed to get download url: \(failure)")
            }
        }
        
        return headerView
    }
    
    @objc private func didTapChangeProfilePicture() {
        print("Change pic called")
        presentPhotoActionSheet()
    }
    
    private func layout() {
        view.addSubview(tableView)
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.frame = view.bounds
    }
}

extension ProfileViewController : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ProfileTableViewCell.identifier, for: indexPath) as! ProfileTableViewCell
        let viewModel = data[indexPath.row]
        cell.setUp(with: viewModel)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        data[indexPath.row].handler?()
    }
}

class ProfileTableViewCell: UITableViewCell {
    
    static let identifier = "ProfileTableViewCell"
    
    public func setUp(with viewModel: ProfileViewModel) {
        textLabel?.text = viewModel.title
        switch viewModel.viewModelType {
        case .info:
            textLabel?.textAlignment = .left
            selectionStyle = .none //set to untappable
        case .logout:
            textLabel?.textColor = .red
            textLabel?.textAlignment = .center
        }
    }
}

extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func presentPhotoActionSheet() {
        let actionSheet = UIAlertController(title: "Profile Picture",
                                            message: "How would you like to select a pticure?",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Cancel",
                                            style: .cancel,
                                            handler: nil))
        
        actionSheet.addAction(UIAlertAction(title: "Take Photo",
                                            style: .default,
                                            handler: { [weak self] _ in
            self?.presentCamera()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Chose Photo",
                                            style: .default,
                                            handler: { [weak self] _ in
            self?.presentPhotoPicker()
        }))
        
        present(actionSheet, animated: true)
    }
    
    func presentCamera() {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func presentPhotoPicker() {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self  //如果沒這行不會觸發didFinishPickingMediaWithInfo
        vc.allowsEditing = true //對應：editedImage
        present(vc, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true, completion: nil) //?
        guard let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage,
              let imageView = self.imageView else { return }
        imageView.image = selectedImage
        
        guard let data = selectedImage.pngData(),
              let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        let fileName = "\(safeEmail)_profile_picture.png"
        StorageManager.shared.uploadProfilePicture(with: data,
                                                   fileName: fileName) { result in
            switch result {
            case .success(let downloadUrl):
                print(downloadUrl)
            case .failure(let error):
                print("Storage manager error: \(error)")
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
