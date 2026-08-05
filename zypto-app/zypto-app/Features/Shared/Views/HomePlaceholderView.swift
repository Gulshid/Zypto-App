//
//  HomePlaceholderView.swift
//  FoodDeliveryApp
//
//  Temporary landing screen shown right after login/signup, so
//  Phase 2 has somewhere to route to and sign-out is testable end
//  to end. Replaced by the real Customer home feed (Phase 4) and
//  Restaurant/Admin dashboard (Phase 7), routed by user.role.
//
//  Location in project: Features/Shared/Views/HomePlaceholderView.swift
//

import SwiftUI

struct HomePlaceholderView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    let user: AppUser

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: user.isRestaurantOwner ? "storefront.fill" : "bag.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.orange)

                Text("Welcome, \(user.fullName.isEmpty ? user.email : user.fullName)")
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)

                Text(user.isRestaurantOwner ? "Restaurant Owner" : "Customer")
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Capsule())

                Text("Phase 2 authentication complete ✅")
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)

                Button(role: .destructive) {
                    authViewModel.signOut()
                } label: {
                    Text("Sign Out").bold()
                }
                .padding(.top, 24)
            }
            .padding()
            .navigationTitle("Home")
        }
    }
}

#Preview {
    HomePlaceholderView(
        user: AppUser(
            id: "1", email: "jane@example.com", fullName: "Jane Doe",
            role: Constants.UserRole.customer, createdAt: .now
        )
    )
    .environmentObject(AuthViewModel.preview)
}
