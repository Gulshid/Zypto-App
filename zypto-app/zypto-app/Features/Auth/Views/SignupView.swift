//
//  SignupView.swift
//  FoodDeliveryApp
//
//  On success, AuthViewModel moves sessionState to .needsRoleSelection —
//  RootView picks that up and swaps to RoleSelectionView automatically,
//  so this view doesn't need to navigate anywhere itself.
//
//  Location in project: Features/Auth/Views/SignupView.swift
//

import SwiftUI

struct SignupView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Binding var showSignup: Bool

    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    private var passwordsMatch: Bool { !password.isEmpty && password == confirmPassword }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header

                VStack(spacing: 16) {
                    TextField("Full name", text: $fullName)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.words)

                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    SecureField("Password (min. 6 characters)", text: $password)
                        .textFieldStyle(.roundedBorder)

                    SecureField("Confirm password", text: $confirmPassword)
                        .textFieldStyle(.roundedBorder)

                    if !confirmPassword.isEmpty && !passwordsMatch {
                        Text("Passwords don't match")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }

                if let error = authViewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task { await authViewModel.signUp(fullName: fullName, email: email, password: password) }
                } label: {
                    Group {
                        if authViewModel.isPerformingAction {
                            ProgressView().tint(.white)
                        } else {
                            Text("Create Account").bold()
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
                .background(.orange)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .disabled(authViewModel.isPerformingAction || fullName.isEmpty || !passwordsMatch)

                HStack {
                    Text("Already have an account?")
                        .foregroundStyle(.secondary)
                    Button("Log in") { showSignup = false }
                        .bold()
                }
                .font(.subheadline)
            }
            .padding(24)
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("Create your account")
                .font(.title.bold())
            Text("Order from your favorite restaurants")
                .foregroundStyle(.secondary)
        }
        .padding(.top, 32)
    }
}

#Preview {
    SignupView(showSignup: .constant(true))
        .environmentObject(AuthViewModel.preview)
}
