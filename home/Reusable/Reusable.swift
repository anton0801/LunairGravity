import SwiftUI

struct FloatingBubble: View {
    let color: Color
    let size: CGFloat
    let duration: Double
    let xAmp: CGFloat
    let yAmp: CGFloat

    @State private var floating = false

    var body: some View {
        Circle()
            .fill(color.opacity(0.5))
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .fill(RadialGradient(colors: [.white.opacity(0.55), .clear],
                                         center: .topLeading,
                                         startRadius: 10,
                                         endRadius: size/2))
                    .scaleEffect(0.8)
            )
            .shadow(color: color.opacity(0.7), radius: 40)
            .blur(radius: 30)
            .offset(x: floating ? xAmp : -xAmp, y: floating ? -yAmp : yAmp)
            .animation(.easeInOut(duration: duration).repeatForever(autoreverses: true), value: floating)
            .onAppear { floating = true }
    }
}

struct AppBackground: View {
    let gradientColors: [Color]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: gradientColors, startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                FloatingBubble(color: Color(hex: "4DDFFF"), size: geo.size.width * 0.6, duration: 26, xAmp: 70, yAmp: 100)
                    .position(x: geo.size.width * 0.3, y: geo.size.height * 0.2)

                FloatingBubble(color: Color(hex: "C266FF"), size: geo.size.width * 0.45, duration: 31, xAmp: 55, yAmp: 85)
                    .position(x: geo.size.width * 0.8, y: geo.size.height * 0.25)

                FloatingBubble(color: Color(hex: "00E6C6"), size: geo.size.width * 0.7, duration: 22, xAmp: 90, yAmp: 120)
                    .position(x: geo.size.width * 0.5, y: geo.size.height * 0.48)

                FloatingBubble(color: Color(hex: "4DDFFF"), size: geo.size.width * 0.4, duration: 29, xAmp: 65, yAmp: 90)
                    .position(x: geo.size.width * 0.15, y: geo.size.height * 0.68)

                FloatingBubble(color: Color(hex: "C266FF"), size: geo.size.width * 0.55, duration: 24, xAmp: 80, yAmp: 100)
                    .position(x: geo.size.width * 0.75, y: geo.size.height * 0.8)
            }
            .blur(radius: 60)
            .opacity(0.9)
        }
    }
}

struct BackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.title2.bold())
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(Circle().fill(.white.opacity(0.15)))
        }
    }
}

struct BubbleButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(LinearGradient(colors: [Color(hex: "FFDDAA"), Color(hex: "FFB84D")],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 170, height: 170)
                .shadow(color: Color(hex: "FFDDAA").opacity(0.9), radius: 60)
                .overlay(Text(title).font(.title.bold()).foregroundColor(Color(hex: "0A0033")))
        }
    }
}

struct QuickModeBubble: View {
    let title: String
    let image: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: image).font(.system(size: 32)).foregroundColor(.white)
                Text(title).font(.caption).foregroundColor(.white)
            }
            .frame(width: 85, height: 85)
            .background(Circle().fill(.white.opacity(0.2)).blur(radius: 20))
            .overlay(Circle().stroke(.white.opacity(0.4), lineWidth: 1.5))
            .shadow(color: .white.opacity(0.4), radius: 15)
        }
    }
}

struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(title).foregroundColor(.white).font(.title3)
            Spacer()
            Button { withAnimation { isOn.toggle() } } label: {
                ZStack {
                    Circle()
                        .fill(isOn ? Color(hex: "00E6C6") : Color.white.opacity(0.15))
                        .frame(width: 70, height: 70)
                    
                    Circle()
                        .fill(.white)
                        .frame(width: 26, height: 26)
                        .opacity(isOn ? 1 : 0)
                }
                .shadow(color: isOn ? Color(hex: "00E6C6").opacity(0.8) : .clear, radius: 20)
            }
        }
        .padding(.horizontal, 50)
    }
}


struct TimerBubble: View {
    let minutes: Int
    @Binding var selected: Int
    @Binding var running: Bool
    @Binding var seconds: Int
    @Binding var opacity: Double

    var body: some View {
        Circle()
            .fill(minutes == selected && !running ? Color(hex: "FFDDAA") : Color.white.opacity(0.2))
            .frame(width: 100, height: 100)
            .overlay(Text("\(minutes)\nmin").multilineTextAlignment(.center).foregroundColor(.white).font(.title3.bold()))
            .onTapGesture {
                selected = minutes
                seconds = minutes * 60
                running = true
                opacity = 1.0
                withAnimation(.linear(duration: Double(minutes * 60))) { opacity = 0.3 }
            }
            .shadow(color: minutes == selected && !running ? Color(hex: "FFDDAA").opacity(0.8) : .clear, radius: 30)
    }
}

struct ThemeBubble: View {
    let index: Int
    let selectedTheme: Int
    let changeTheme: (Int) -> Void

    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(themes[index][1])
                .frame(width: 80, height: 80)
                .overlay(
                    Circle()
                        .stroke(Color(hex: "FFDDAA"), lineWidth: index == selectedTheme ? 4 : 0)
                )
                .shadow(color: themes[index][1].opacity(0.8), radius: 20)
            Text(["Night", "Sunset", "Ocean"][index])
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .onTapGesture { changeTheme(index) }
    }
}

struct StatText: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title).foregroundColor(.white.opacity(0.8))
            Spacer()
            Text(value).font(.title3.bold()).foregroundColor(.white)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 15).fill(.white.opacity(0.15)))
    }
}
