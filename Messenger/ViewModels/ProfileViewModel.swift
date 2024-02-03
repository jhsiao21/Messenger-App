//
//  ProfileViewModel.swift
//  Messenger
//
//  Created by LoganMacMini on 2024/2/3.
//

import Foundation


enum ProfileViewModelType {
    case info
    case logout
}

struct ProfileViewModel {
    let viewModelType: ProfileViewModelType
    let title: String
    let handler: (() -> Void)?
}
