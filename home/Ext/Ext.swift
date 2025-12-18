import Foundation
import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 255, 255, 255)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// Глобальные темы — теперь вне любого типа
let themes: [[Color]] = [
    [Color(hex: "0A0033"), Color(hex: "1A004D"), Color(hex: "002266")], // Night
    [Color(hex: "2C0048"), Color(hex: "5E0080"), Color(hex: "8B00B3")], // Sunset
    [Color(hex: "001F33"), Color(hex: "003355"), Color(hex: "005588")]  // Ocean
]
