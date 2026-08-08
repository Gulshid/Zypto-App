//
//  SkeletonView.swift
//  FoodDeliveryApp
//
//  New in Phase 10. Shimmering skeleton placeholders that replace the
//  plain ProgressView spinners used everywhere since Phase 4 — while a
//  restaurant list, menu, or order list is loading, the screen now
//  shows gray shapes in roughly the size/position of the real content
//  instead of a blank screen with a spinner in the middle. This makes
//  the loading state feel faster and tells the person what kind of
//  content is about to appear.
//
//  Location in project: Features/Shared/Views/SkeletonView.swift
//
//  Two layers:
//   1. `.shimmering()` — a view modifier that sweeps a soft highlight
//      across any view. Used on `SkeletonBox` below, and (via
//      `ShimmerPlaceholder`) as CachedAsyncImage's default placeholder
//      — see Features/Shared/Views/CachedAsyncImage.swift.
//   2. Row-shaped skeletons (`RestaurantCardSkeleton`,
//      `MenuItemRowSkeleton`, `OrderRowSkeleton`,
//      `IncomingOrderRowSkeleton`) that mirror the exact layout of the
//      real row view they stand in for, so the transition from
//      skeleton -> real content doesn't visibly jump around.
//

import SwiftUI

// MARK: - Shimmer effect

private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -0.6
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay {
                // Reduce Motion: skip the moving sweep entirely and just
                // show the base color — still communicates "loading" via
                // the shape, without the animated motion some people
                // have asked iOS to minimize.
                if !reduceMotion {
                    GeometryReader { proxy in
                        LinearGradient(
                            colors: [.clear, Color.white.opacity(0.35), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: proxy.size.width * 1.4)
                        .offset(x: phase * proxy.size.width)
                    }
                    .blendMode(.plusLighter)
                }
            }
            .clipped()
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 1.3).repeatForever(autoreverses: false)) {
                    phase = 1.2
                }
            }
    }
}

extension View {
    /// Applies the sweeping shimmer highlight used by every skeleton
    /// shape in this file. Automatically disabled when the person has
    /// Reduce Motion turned on.
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}

/// A single rounded gray shape — the basic building block every
/// skeleton row below is assembled from.
struct SkeletonBox: View {
    var cornerRadius: CGFloat = 6

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color(.secondarySystemBackground))
            .shimmering()
    }
}

/// CachedAsyncImage's default placeholder (see
/// Features/Shared/Views/CachedAsyncImage.swift) — a plain shimmering
/// box, used any time an image is loading or has no URL yet.
struct ShimmerPlaceholder: View {
    var body: some View {
        SkeletonBox(cornerRadius: 0)
    }
}

// MARK: - Row-shaped skeletons

/// Stands in for RestaurantCardView (Features/Home/Views) while the
/// home feed's initial restaurant list is loading.
struct RestaurantCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SkeletonBox(cornerRadius: 14)
                .aspectRatio(16.0 / 9.0, contentMode: .fill)

            VStack(alignment: .leading, spacing: 6) {
                SkeletonBox()
                    .frame(width: 160, height: 16)
                SkeletonBox()
                    .frame(width: 110, height: 12)
                SkeletonBox()
                    .frame(width: 70, height: 12)
            }
        }
        .accessibilityHidden(true)
    }
}

/// Stands in for MenuItemRowView (Features/RestaurantDetail/Views)
/// while a restaurant's menu is loading.
struct MenuItemRowSkeleton: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                SkeletonBox()
                    .frame(width: 140, height: 15)
                SkeletonBox()
                    .frame(width: 200, height: 12)
                SkeletonBox()
                    .frame(width: 50, height: 14)
                    .padding(.top, 2)
            }
            Spacer(minLength: 8)
            SkeletonBox(cornerRadius: 10)
                .frame(width: 72, height: 72)
        }
        .padding(.horizontal)
        .accessibilityHidden(true)
    }
}

/// Stands in for OrderRowView / IncomingOrderRowView while an order
/// list (customer history or the restaurant's incoming-orders tab) is
/// loading.
struct OrderRowSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SkeletonBox()
                    .frame(width: 130, height: 15)
                Spacer()
                SkeletonBox(cornerRadius: 10)
                    .frame(width: 70, height: 20)
            }
            SkeletonBox()
                .frame(width: 150, height: 12)
            SkeletonBox()
                .frame(width: 100, height: 11)
        }
        .padding(.vertical, 6)
        .accessibilityHidden(true)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            ForEach(0..<2, id: \.self) { _ in RestaurantCardSkeleton() }
            Divider()
            ForEach(0..<2, id: \.self) { _ in MenuItemRowSkeleton() }
            Divider()
            ForEach(0..<2, id: \.self) { _ in OrderRowSkeleton().padding(.horizontal) }
        }
        .padding(.vertical)
    }
}
