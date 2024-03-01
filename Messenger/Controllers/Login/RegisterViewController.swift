//
//  RegisterViewController.swift
//  Messenger
//
//  Created by LoganMacMini on 2024/1/25.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

final class RegisterViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private let scrollView : UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person.circle")
        imageView.tintColor = .gray
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
        //        imageView.layer.cornerRadius = imageView.frame.size.width / 2
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        return imageView
    }()
    
    private let firstNameField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "First name..."
        //leftView可以指定左邊的view內容，這裡指定一個空的UIView，寬度５
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        return field
    }()
    
    private let lastNameField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Last name..."
        //leftView可以指定左邊的view內容，這裡指定一個空的UIView，寬度５
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        return field
    }()
    
    private let emailField: CustomTextField = {
        let field = CustomTextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Email Address..."
        //leftView可以指定左邊的view內容，這裡指定一個空的UIView，寬度５
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        return field
    }()
    
    private let emailValidationLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.textColor = .red
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.isHidden = true
        return label
    }()
    
    private let passwordField: CustomTextField = {
        let field = CustomTextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        //done?
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Password..."
        //leftView可以指定左邊的view內容，這裡指定一個空的UIView，寬度５
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        field.isSecureTextEntry = true
        return field
    }()
    
    private let passwordValidationLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.textColor = .red
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.isHidden = true
        return label
    }()
    
    private let checkPasswordField: CustomTextField = {
        let field = CustomTextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done //最後一個文字輸入框的小鍵盤顯示done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Password Again..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        field.isSecureTextEntry = true
        return field
    }()
    
    private let checkPasswordLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.textColor = .red
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.isHidden = true
        return label
    }()
    
    private let registerButton: UIButton = {
        let button = UIButton()
        button.setTitle("Register", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    private var correctEmail = false
    private var correctPassword = false
    private var samePassword = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Login"
        view.backgroundColor = .systemBackground
                
        registerButton.addTarget(self,
                                 action: #selector(registerButtonTapped),
                                 for: .touchUpInside)
        
        emailField.delegate = self
        passwordField.delegate = self
        
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(firstNameField)
        scrollView.addSubview(lastNameField)
        scrollView.addSubview(emailField)
        scrollView.addSubview(emailValidationLabel)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(passwordValidationLabel)
        scrollView.addSubview(checkPasswordField)
        scrollView.addSubview(checkPasswordLabel)
        scrollView.addSubview(registerButton)
        
        imageView.isUserInteractionEnabled = true
        
        let gestureImageView = UITapGestureRecognizer(target: self,
                                             action: #selector(didTapChangeProfilePic))
        imageView.addGestureRecognizer(gestureImageView)
        
        let gestureClearKeyboard = UITapGestureRecognizer(target: self, action: #selector(tappedHandle))
        view.addGestureRecognizer(gestureClearKeyboard)
                
        
        setupTextField()
    }
    
    @objc func didTapChangeProfilePic() {
        print("Change pic called")
        presentPhotoActionSheet()
    }
    
    @objc private func tappedHandle() {
        // clear keyboard
        firstNameField.resignFirstResponder()
        lastNameField.resignFirstResponder()
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        checkPasswordField.resignFirstResponder()
    }
    
    // MARK: Format Check
    private func setupTextField() {
        emailField.textValidation { [weak self] text in
            guard let strongSelf = self else {
                return
            }
            let isValidEmail = text.emailValidation()
            strongSelf.emailValidationLabel.isHidden = false
            if isValidEmail {
                self?.emailValidationLabel.text = ""
                strongSelf.correctEmail = true
            }
            else {
                self?.emailValidationLabel.text = "Email is not valid!"
                strongSelf.correctEmail = false
            }
        }
        
        passwordField.textValidation { [weak self] text in
            guard let strongSelf = self else {
                return
            }
            let isValidPassword = text.passwordValidation()
            self?.passwordValidationLabel.isHidden = false
            if isValidPassword {
                self?.passwordValidationLabel.text = ""
                strongSelf.correctPassword = true
            }
            else {
                self?.passwordValidationLabel.text = "At least 8 characters"
                strongSelf.correctPassword = false
            }
        }
        
        checkPasswordField.textValidation { [weak self] text in
            guard let strongSelf = self else {
                return
            }
            self?.checkPasswordLabel.isHidden = false
            if(self?.passwordField.text != self?.checkPasswordField.text) {
                self?.checkPasswordLabel.text =  "Password is not the same!"
                strongSelf.samePassword = false
            }
            else {
                self?.checkPasswordLabel.text =  ""
                strongSelf.samePassword = true
            }
        }
    }
        
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        
        let size = scrollView.width / 3
        imageView.frame = CGRect(x: (scrollView.width - size) / 2,
                                 y: 20,
                                 width: size,
                                 height: size)
        imageView.layer.cornerRadius = imageView.width / 2
        
        firstNameField.frame = CGRect(x: 30,
                                      y: imageView.bottom + 20,
                                      width: scrollView.width - 60,
                                      height: 52)
        lastNameField.frame = CGRect(x: 30,
                                     y: firstNameField.bottom + 20,
                                     width: scrollView.width - 60,
                                     height: 52)
        emailField.frame = CGRect(x: 30,
                                  y: lastNameField.bottom + 20,
                                  width: scrollView.width - 60,
                                  height: 52)
        emailValidationLabel.frame = CGRect(x: 35,
                                                y: emailField.bottom + 3,
                                                width: scrollView.width-60,
                                                height: 14)
        passwordField.frame = CGRect(x: 30,
                                     y: emailValidationLabel.bottom + 3,
                                     width: scrollView.width - 60,
                                     height: 52)
        passwordValidationLabel.frame = CGRect(x: 35,
                                               y: passwordField.bottom + 3,
                                               width: scrollView.width - 60,
                                               height: 14)
        checkPasswordField.frame = CGRect(x: 30,
                                          y: passwordValidationLabel.bottom + 3,
                                          width: scrollView.width - 60,
                                          height: 52)
        checkPasswordLabel.frame = CGRect(x: 35,
                                          y: checkPasswordField.bottom + 3,
                                          width: scrollView.width - 60,
                                          height: 14)
        registerButton.frame = CGRect(x: 30,
                                   y: checkPasswordLabel.bottom + 15,
                                   width: scrollView.width - 60,
                                   height: 52)
    }
    
    @objc private func registerButtonTapped() {
        
        firstNameField.resignFirstResponder()
        lastNameField.resignFirstResponder()
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
                
        guard let firstName = firstNameField.text,
              let lastName = lastNameField.text,
              let email = emailField.text,
              let password = passwordField.text,
              !firstName.isEmpty,
              !lastName.isEmpty,
              !email.isEmpty,
              !password.isEmpty,
              password.count >= 6 else {
//            alertUserLoginError()
            self.showUIAlert(message: "Please enter all information to create a new account")
            return
        }
        
        guard correctEmail == true,
              correctPassword == true,
              samePassword == true else {
//            print("can not register")
            self.showUIAlert(message: "Can not register")
            return
        }
        
        spinner.show(in: view) //show in current view
        
        //Firebase login
        DatabaseManager.shared.userExists(with: email) { [weak self] exists in
            guard let strongSelf = self else { return }
            
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }
            
            guard !exists else {
                //user already exists
                self?.alertUserLoginError(message: "Looks like a user account for that email address already exists.")
                return
            }
            
            FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                
                guard authResult != nil, error == nil else {
                    print("Error creating user")
                    return
                }
                
                // set name and email to disk
                UserDefaults.standard.setValue("\(firstName) \(lastName)", forKey: "name")
                UserDefaults.standard.setValue(email, forKey: "email")
                
                let chatUser = ChatAppUser(firstName: firstName,
                                           lastName: lastName,
                                           emailAddress: email)
                DatabaseManager.shared.insertUser(with: chatUser) { result in
                    
                    switch result {
                    case .success(_):
                        //upload image
                        guard let image = strongSelf.imageView.image,
                              let data = image.pngData() else {
                            return
                        }
                        let filename = chatUser.profilePictureFileName
                        StorageManager.shared.uploadProfilePicture(with: data, fileName: filename) { result in
                            switch result {
                                
                            case .success(let downloadUrl):
                                UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")   //save to disk
                                print(downloadUrl)
                            case .failure(let error):
                                print("Storage manager error: \(error)")
                            }
                        }
                    case .failure(let error):
                        let errMsg = "Failed to get users, error: \(error.errorDescription)"
                        self?.showUIAlert(message: errMsg)
                    }
                }
                
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func alertUserLoginError(message: String = "Please enter all information to create a new account") {
        let alert = UIAlertController(title: "Oops",
                                      message: message,
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Dismiss",
                                      style: .cancel,
                                      handler: nil))
        
        present(alert, animated: true)
    }
}

extension RegisterViewController : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == emailField {
            passwordField.becomeFirstResponder()
        }
        else if textField == passwordField {
            registerButtonTapped()
        }
        
        return true
    }
}

extension RegisterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
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
        guard let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else { return }
        imageView.image = selectedImage
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
