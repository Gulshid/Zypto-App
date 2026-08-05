//
//  Validators.swift
//  FoodDeliveryApp
//
//  Small, dependency-free form validation helpers shared by
//  Login / Signup / Forgot Password screens.
//
//  Location in project: Core/Utils/Validators.swift
//

import Foundation

enum Validators {

    static func isValidEmail(_ email: String) -> Bool {
        let regex = #"^[\w.+-]+@[\w-]+\.[A-Za-z]{2,}$"#
        return email.range(of: regex, options: .regularExpression) != nil
    }

    /// Firebase Auth itself rejects passwords under 6 characters, so this
    /// just catches the error earlier with a friendlier inline message.
    static func isValidPassword(_ password: String) -> Bool {
        password.count >= 6
    }
}
