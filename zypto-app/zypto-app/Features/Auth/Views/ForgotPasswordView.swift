//
//  ForgotPasswordView.swift
//  FoodDeliveryApp
//
//  Presented as a sheet from LoginView.
//
//  Location in project: Features/Auth/Views/ForgotPasswordView.swift
//

import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var email: String
    @State private var didSend = false

    init(prefillEmail: String = "") {
        _email = State(initialValue: prefillEmail)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Enter the email tied to your account and we'll send a reset link.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                if didSend {
                    Label("Reset email sent — check your inbox.", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.footnote)
                }

                if let error = authViewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Button {
                    Task {
                        didSend = await authViewModel.sendPasswordReset(email: email)
                    }
                } label: {
                    Group {
                        if authViewModel.isPerformingAction {
                            ProgressView().tint(.white)
                        } else {
                            Text("Send Reset Link").bold()
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
                .background(.orange)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .disabled(email.isEmpty || authViewModel.isPerformingAction)

                Spacer()
            }
            .padding(24)
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ForgotPasswordView(prefillEmail: "test@example.com")
        .environmentObject(AuthViewModel.preview)
}
