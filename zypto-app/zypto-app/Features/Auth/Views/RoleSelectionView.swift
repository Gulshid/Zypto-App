//
//  RoleSelectionView.swift
//  FoodDeliveryApp
//
//  Shown right after the very first sign-up (email/password or Google)
//  before a Firestore `users` profile exists. Picking a role here is
//  what actually creates that profile via AuthViewModel.completeProfile.
//
//  Location in project: Features/Auth/Views/RoleSelectionView.swift
//

import SwiftUI

struct RoleSelectionView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel

    let uid: String
    let email: String
    @State var fullName: String

    @State private var selectedRole: String?

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                Text("One last step")
                    .font(.title.bold())
                Text("How will you be using the app?")
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 48)

            if fullName.isEmpty {
                TextField("Full name", text: $fullName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 24)
            }

            VStack(spacing: 16) {
                roleCard(
                    role: Constants.UserRole.customer,
                    title: "I'm a Customer",
                    subtitle: "Browse restaurants and order food",
                    icon: "bag.fill"
                )
                roleCard(
                    role: Constants.UserRole.restaurantOwner,
                    title: "I'm a Restaurant Owner",
                    subtitle: "Manage my menu and incoming orders",
                    icon: "storefront.fill"
                )
            }
            .padding(.horizontal, 24)

            if let error = authViewModel.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Spacer()

            Button {
                guard let selectedRole else { return }
                Task {
                    await authViewModel.completeProfile(
                        uid: uid, email: email, fullName: fullName, role: selectedRole
                    )
                }
            } label: {
                Group {
                    if authViewModel.isPerformingAction {
                        ProgressView().tint(.white)
                    } else {
                        Text("Continue").bold()
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(.orange)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .disabled(selectedRole == nil || fullName.isEmpty || authViewModel.isPerformingAction)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    private func roleCard(role: String, title: String, subtitle: String, icon: String) -> some View {
        let isSelected = selectedRole == role
        return Button {
            selectedRole = role
        } label: {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .background(isSelected ? Color.orange : Color(.secondarySystemBackground))
                    .foregroundStyle(isSelected ? .white : .primary)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(title).bold()
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.orange)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground).opacity(isSelected ? 0.6 : 0.3))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RoleSelectionView(uid: "abc", email: "test@example.com", fullName: "")
        .environmentObject(AuthViewModel.preview)
}
