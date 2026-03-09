import SwiftUI

// MARK: - Shimmer Effect

struct Shimmer: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [.clear, .white.opacity(0.04), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 300
                }
            }
    }
}

extension View {
    func shimmer() -> some View { modifier(Shimmer()) }
}

struct SkeletonPill: View {
    var width: CGFloat
    var height: CGFloat = 12

    var body: some View {
        RoundedRectangle(cornerRadius: height / 2)
            .fill(Theme.secondary)
            .frame(width: width, height: height)
    }
}
