
import SwiftUI
import Combine
import Charts

struct MainScreen: View {
    let onNavigate: (SleepRelaxView.Screen) -> Void

    var body: some View {
        VStack(spacing: 50) {
            HStack {
                Spacer()
                Button { onNavigate(.settings) } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 50, height: 50)
                        .background(Circle().fill(.white.opacity(0.15)))
                }
                .padding(.top, 60)
                .padding(.trailing, 30)
            }

            Spacer()

            Text("Time to relax")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            BubbleButton(title: "Start") { onNavigate(.breathing) }

            HStack(spacing: 30) {
                QuickModeBubble(title: "Breathing", image: "lungs.fill") { onNavigate(.breathing) }
                QuickModeBubble(title: "Advanced Breath", image: "wind") { onNavigate(.advancedBreathing) }
                QuickModeBubble(title: "Progress", image: "chart.bar") { onNavigate(.progress) }
            }

            Spacer()
            Spacer()
        }
    }
}


@main
struct SleepRelaxApp: App {
    
    @UIApplicationDelegateAdaptor(GravityPlusAppDelegate.self) var gravityPlusAppDelegate
    
    var body: some Scene {
        WindowGroup {
            SplashGravityView()
        }
    }
}


struct ZenBallProgressView: View {
    @State private var progress: CGFloat = 0.0
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(gradient: Gradient(colors: [Color.white, Color.blue.opacity(0.5), .clear]),
                                     center: .center, startRadius: 0, endRadius: 100))
                .frame(width: 120, height: 120)
                .scaleEffect(isAnimating ? 1.1 : 0.9)
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isAnimating)
                .onAppear {
                    isAnimating = true
                }
                .shadow(color: .blue.opacity(0.6), radius: 20)
        }
    }
}

struct LunAirSplashView: View {
    @State var visible = true
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Фон
                Image("loading_app_background")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .ignoresSafeArea()
                    .scaleEffect(1.05)
                
                // Плавающие частицы для атмосферы
                ForEach(0..<8) { i in
                    FloatingParticle(size: CGFloat.random(in: 20...50),
                                     color: [Color.blue, Color.purple, Color.cyan].randomElement()!,
                                     delay: Double(i) * 0.5,
                                     xOffset: CGFloat.random(in: -100...100),
                                     yOffset: CGFloat.random(in: 100...200))
                        .position(x: geo.size.width * CGFloat.random(in: 0.1...0.9),
                                  y: geo.size.height * CGFloat.random(in: 0.6...0.9))
                }
                
                VStack {
                    Spacer()
                    
                    Image("loading")
                        .resizable()
                        .frame(width: 200, height: 50)
                        .opacity(visible ? 1.0 : 0.0)
                        .scaleEffect(0.8)
                        .animation(.easeIn(duration: 1.0).repeatForever(autoreverses: true), value: UUID())
                        .scaleEffect(1.05)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: UUID())
                    
                    Spacer()
                    
                    ZenBallProgressView()
                        .frame(width: 280)
                        .padding(.bottom, 52)
                }
            }
        }
        .ignoresSafeArea()
    }
}


