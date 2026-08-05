//
//  AuthContainerView.swift
//  FoodDeliveryApp
//
//  Hosts the Login <-> Signup toggle inside a NavigationStack so
//  ForgotPasswordView (presented as a sheet) and future push
//  destinations have somewhere to attach to.
//
//  Location in project: Features/Auth/Views/AuthContainerView.swift
//

import SwiftUI

struct AuthContainerView: View {
    @State private var showSignup = false

    var body: some View {
        NavigationStack {
            Group {
                if showSignup {
                    SignupView(showSignup: $showSignup)
                } else {
                    LoginView(showSignup: $showSignup)
                }
            }
        }
    }
}

#Preview {
    AuthContainerView()
        .environmentObject(AuthViewModel.preview)
}
