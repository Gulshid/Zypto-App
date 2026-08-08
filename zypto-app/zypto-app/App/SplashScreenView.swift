//
//  SplashScreenView.swift
//  FoodDeliveryApp
//
//  A branded launch experience shown while AuthViewModel resolves the
//  session (AuthSessionState.loading, see App/FoodDeliveryApp.swift).
//  A native storyboard launch screen can't animate, so this SwiftUI
//  view is what the person actually sees settle into place: the mark
//  scales/fades in, the tagline follows a beat later, and a thin
//  progress indicator confirms something's happening without
//  competing with the brand moment above it.
//
//  Location in project: App/SplashScreenView.swift
//
//  Kept deliberately dependency-free (no ViewModel, no repositories)
//  so it can render instantly on cold launch, before AppEnvironment's
//  Firebase-backed services have had a chance to do anything.
//

import SwiftUI

struct SplashScreenView: View {
    /// Drives the logo's entrance. Split into its own flag (rather than
    /// a single `.onAppear { withAnimation { ... } }`) so the mark and
    /// the tagline can be staged a beat apart below.
    @State private var isLogoVisible = false
    @State private var isTaglineVisible = false
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            // Soft decorative glow, purely atmospheric — kept behind
            // the logo and never interactive.
            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: 340, height: 340)
                .blur(radius: 20)
                .scaleEffect(isPulsing ? 1.08 : 0.92)
                .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: isPulsing)

            VStack(spacing: 18) {
                Spacer()

                logoMark
                    .scaleEffect(isLogoVisible ? 1 : 0.6)
                    .opacity(isLogoVisible ? 1 : 0)

                VStack(spacing: 6) {
                    Text("Zypto")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .tracking(1)

                    Text("Delicious, delivered fast.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .opacity(isTaglineVisible ? 1 : 0)
                .offset(y: isTaglineVisible ? 0 : 10)

                Spacer()

                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .opacity(isTaglineVisible ? 1 : 0)
                    .padding(.bottom, 48)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.62)) {
                isLogoVisible = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.25)) {
                isTaglineVisible = true
            }
            isPulsing = true
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color.orange, Color(red: 0.93, green: 0.35, blue: 0.13)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var logoMark: some View {
        ZStack {
            Circle()
                .fill(.white)
                .frame(width: 108, height: 108)
                .shadow(color: .black.opacity(0.15), radius: 16, y: 8)

            Image(systemName: "fork.knife")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(Color.orange)
        }
    }
}

#Preview {
    SplashScreenView()
}
