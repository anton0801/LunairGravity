import Foundation
import SwiftUI

struct TimerSession: Codable {
    let date: Date
    let duration: Int
}

enum BreathingMode {
    case basic
    case fourSevenEight
    case box
    case alternateNostril
    case custom
    
    var phases: [(text: String, duration: Double, scale: CGFloat)] {
        switch self {
        case .basic:
            return [
                ("Inhale...", 4.0, 2.0),
                ("Hold...", 4.0, 2.0),
                ("Exhale...", 4.0, 1.0)
            ]
        case .fourSevenEight:
            return [
                ("Inhale...", 4.0, 2.0),
                ("Hold...", 7.0, 2.0),
                ("Exhale...", 8.0, 1.0)
            ]
        case .box:
            return [
                ("Inhale...", 4.0, 2.0),
                ("Hold...", 4.0, 2.0),
                ("Exhale...", 4.0, 1.0),
                ("Hold...", 4.0, 1.0)
            ]
        case .alternateNostril:
            return [
                ("Inhale Left...", 4.0, 2.0),
                ("Hold...", 4.0, 2.0),
                ("Exhale Right...", 4.0, 1.0),
                ("Inhale Right...", 4.0, 2.0),
                ("Hold...", 4.0, 2.0),
                ("Exhale Left...", 4.0, 1.0)
            ]
        case .custom:
            // Будет передаваться отдельно, но для fallback
            return [
                ("Inhale...", 4.0, 2.0),
                ("Hold...", 4.0, 2.0),
                ("Exhale...", 4.0, 1.0)
            ]
        }
    }
}


struct FloatingParticle: View {
    let size: CGFloat
    let color: Color
    let delay: Double
    let xOffset: CGFloat
    let yOffset: CGFloat
    
    @State private var opacity: Double = 0.0
    @State private var position: CGPoint = .zero
    
    var body: some View {
        Circle()
            .fill(color.opacity(0.6))
            .frame(width: size, height: size)
            .blur(radius: size / 4)
            .offset(x: position.x, y: position.y)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 3.0 + delay).repeatForever(autoreverses: false)) {
                    opacity = 0.0
                    position = CGPoint(x: xOffset * 2, y: -yOffset * 3) // Движение вверх и в стороны
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation {
                        opacity = 1.0
                    }
                }
            }
    }
}
