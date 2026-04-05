import SwiftUI

struct Theme {
    static let background = Color(hex: "#050505")
    static let foreground = Color(hex: "#f0f0f0")
    
    static let card = Color(hex: "#111111")
    static let cardForeground = Color(hex: "#f0f0f0")
    
    static let cardElevated = Color(hex: "#181818")
    
    static let primary = Color(hex: "#f0f0f0")
    static let primaryForeground = Color(hex: "#050505")
    
    static let secondary = Color(hex: "#161616")
    static let secondaryForeground = Color(hex: "#e0e0e0")
    
    static let muted = Color(hex: "#1a1a1a")
    static let mutedForeground = Color(hex: "#8a8a8a")
    
    static let border = Color(hex: "#222222")
    static let input = Color(hex: "#161616")
    static let highlight = Color(hex: "#f0f0f0")
    
    static let accent = Color(hex: "#6366f1")
    static let accentSubtle = Color(hex: "#6366f1").opacity(0.15)
    
    static let radiusSm: CGFloat = 6.0
    static let radiusMd: CGFloat = 10.0
    static let radiusLg: CGFloat = 14.0
    static let radiusXl: CGFloat = 20.0
    static let radiusFull: CGFloat = 100.0
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
