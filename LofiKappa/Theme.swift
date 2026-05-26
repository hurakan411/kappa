import SwiftUI

struct Theme {
    struct Colors {
        // Lofi Color Palette (Cozy Journal Style)
        static let baseBackgroundLight = Color(hex: "EBF4F2") // 爽やかでコジーな薄水色・薄緑（ミントアクア）
        static let baseBackgroundDark = Color(hex: "111C1A")  // 深い森の泉のようなグリーンチャコール
        static let paperCardLight = Color(hex: "F7FBFB")      // 手帳のページ（極めて明るいペールミント）
        static let paperCardDark = Color(hex: "1A2624")       // ダーク時のカード
        static let textDark = Color(hex: "2D3E3A")            // 万年筆のインク風フォレストチャコールグレー
        static let textLight = Color(hex: "E2EFEA")           // ペールセージグリーンホワイト
        
        static let primaryBlue = Color(hex: "60A5FA")         // 潤いの水色（お皿の水、プログレスバー）
        static let lightBlue = Color(hex: "93C5FD")           // 淡いパステルブルー（サブアクセント）
        
        static let kappaGreenLight = Color(hex: "A7F3D0")     // かっぱの基本色（淡いミント）
        static let kappaGreenDark = Color(hex: "34D399")      // アクセントグリーン
        
        static let penaltyRust = Color(hex: "FCA5A5")         // 警告・お皿が溢れた時のサビ茶・サーモンピンク
        
        static func background(for scheme: ColorScheme) -> Color {
            scheme == .dark ? baseBackgroundDark : baseBackgroundLight
        }
        static func card(for scheme: ColorScheme) -> Color {
            scheme == .dark ? paperCardDark : paperCardLight
        }
        static func text(for scheme: ColorScheme) -> Color {
            scheme == .dark ? textLight : textDark
        }
    }
}

// MARK: - Hand-Drawn Stylized UI Elements

struct HandDrawnDivider: View {
    let color: Color
    var body: some View {
        GeometryReader { geo in
            Path { path in
                path.move(to: CGPoint(x: 0, y: 1))
                let width = geo.size.width
                let steps = Int(width / 12)
                for i in 1...steps {
                    let x = CGFloat(i) * 12
                    let y = 1.0 + sin(x * 0.15) * 0.4 // 固定のうねりで手描き風に
                    path.addLine(to: CGPoint(x: min(x, width), y: y))
                }
            }
            .stroke(color, lineWidth: 1.2)
        }
        .frame(height: 3)
    }
}

struct HandDrawnDoubleBorder: ViewModifier {
    let color: Color
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(color.opacity(0.35), lineWidth: 1.2)
                    .padding(2.5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(color.opacity(0.75), lineWidth: 0.9)
            )
    }
}

extension View {
    func handDrawnBorder(color: Color, cornerRadius: CGFloat = 16) -> some View {
        self.modifier(HandDrawnDoubleBorder(color: color, cornerRadius: cornerRadius))
    }
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

