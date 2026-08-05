//
//  LoginView.swift
//  FoodDeliveryApp
//
//  Location in project: Features/Auth/Views/LoginView.swift
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Binding var showSignup: Bool

    @State private var email = ""
    @State private var password = ""
    @State private var showForgotPassword = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header

                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        Spacer()
                        Button("Forgot password?") { showForgotPassword = true }
                            .font(.footnote)
                    }
                }

                if let error = authViewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task { await authViewModel.signIn(email: email, password: password) }
                } label: {
                    Group {
                        if authViewModel.isPerformingAction {
                            ProgressView().tint(.white)
                        } else {
                            Text("Log In").bold()
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
                .background(.orange)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .disabled(authViewModel.isPerformingAction || email.isEmpty || password.isEmpty)

                dividerWithText("or")

                Button {
                    Task { await authViewModel.signInWithGoogle() }
                } label: {
                    HStack {
                        Image(systemName: "g.circle.fill")
                        Text("Continue with Google")
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .disabled(authViewModel.isPerformingAction)

                HStack {
                    Text("Don't have an account?")
                        .foregroundStyle(.secondary)
                    Button("Sign up") { showSignup = true }
                        .bold()
                }
                .font(.subheadline)
            }
            .padding(24)
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView(prefillEmail: email)
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.orange)
            Text("Welcome back")
                .font(.title.bold())
            Text("Log in to keep ordering")
                .foregroundStyle(.secondary)
        }
        .padding(.top, 32)
    }

    private func dividerWithText(_ text: String) -> some View {
        HStack {
            VStack { Divider() }
            Text(text).font(.footnote).foregroundStyle(.secondary)
            VStack { Divider() }
        }
    }
}

#Preview {
    LoginView(showSignup: .constant(false))
        .environmentObject(AuthViewModel.preview)
}
