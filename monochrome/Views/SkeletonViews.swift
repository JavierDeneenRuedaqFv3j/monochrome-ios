import SwiftUI

// MARK: - Shimmer Effect

struct Shimmer: ViewModifier {
    @State private var phase: CGFloat = -200

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [.clear, .white.opacity(0.06), .white.opacity(0.03), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 200)
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 400
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
            .fill(
                LinearGradient(
                    colors: [Theme.secondary, Theme.secondary.opacity(0.6)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: height)
    }
}
