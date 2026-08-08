//
//  AccountView.swift
//  FoodDeliveryApp
//
//  New in Phase 11. The Account tab: the signed-in customer's profile
//  summary and Sign Out — previously a bare toolbar button on
//  HomeView, now its own screen inside MainTabView's bottom tab bar
//  (Features/Home/Views/MainTabView.swift).
//
//  Location in project: Features/Account/Views/AccountView.swift
//

import SwiftUI

struct AccountView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var isConfirmingSignOut = false

    let currentUser: AppUser

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    initialsAvatar

                    VStack(alignment: .leading, spacing: 2) {
                        Text(currentUser.fullName)
                            .font(.headline)
                        Text(currentUser.email)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 6)
            }

            Section("Account") {
                LabeledContent("Role", value: currentUser.isCustomer ? "Customer" : "Restaurant Owner")
            }

            Section {
                Button(role: .destructive) {
                    isConfirmingSignOut = true
                } label: {
                    HStack {
                        Text("Sign Out")
                        Spacer()
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                }
            }

            Section {
                HStack {
                    Spacer()
                    Text("Zypto")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("Account")
        .confirmationDialog(
            "Sign out of Zypto?",
            isPresented: $isConfirmingSignOut,
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) {
                authViewModel.signOut()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var initialsAvatar: some View {
        Circle()
            .fill(Color.orange.opacity(0.15))
            .overlay(
                Text(initials)
                    .font(.title3.bold())
                    .foregroundStyle(Color.orange)
            )
            .frame(width: 56, height: 56)
    }

    private var initials: String {
        let parts = currentUser.fullName.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return letters.isEmpty ? "?" : String(letters).uppercased()
    }
}
