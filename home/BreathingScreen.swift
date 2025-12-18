import SwiftUI
import Combine

struct BreathingScreen: View {
    let onNavigate: (SleepRelaxView.Screen) -> Void
    let mode: BreathingMode
    let onSessionComplete: () -> Void
    
    @AppStorage("customInhale") private var customInhale: Double = 4.0
    @AppStorage("customHold") private var customHold: Double = 4.0
    @AppStorage("customExhale") private var customExhale: Double = 4.0
    
    @State private var scale: CGFloat = 1.0
    @State private var breathText = "Inhale..."
    @State private var phase = 0
    @State private var phases: [(text: String, duration: Double, scale: CGFloat)] = []
    
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect() // Более частый для точности
    @State private var currentDuration: Double = 0.0
    @State private var elapsed: Double = 0.0

    var body: some View {
        VStack {
            BackButton { onNavigate(.main) }

            Spacer()

            Text("Breathe with the light")
                .font(.title.bold())
                .foregroundColor(.white)
                .padding(.horizontal, 40)

            ZStack {
                Circle()
                    .fill(Color(hex: "00E6C6").opacity(0.75))
                    .scaleEffect(scale)
                    .blur(radius: 50)
                    .frame(width: 340, height: 340)
                    .shadow(color: Color(hex: "00E6C6").opacity(0.9), radius: 70)

                Text(breathText)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(40)

            Spacer()

            Button {
                onSessionComplete()
                onNavigate(.sleepTimer)
            } label: {
                Circle()
                    .fill(Color(hex: "FFDDAA"))
                    .frame(width: 80, height: 80)
                    .overlay(Image(systemName: "checkmark").font(.largeTitle).foregroundColor(Color(hex: "0A0033")))
                    .shadow(color: Color(hex: "FFDDAA").opacity(0.8), radius: 30)
            }
            .padding(.bottom, 100)
        }
        .onAppear {
            if mode == .custom {
                phases = [
                    ("Inhale...", customInhale, 2.0),
                    ("Hold...", customHold, 2.0),
                    ("Exhale...", customExhale, 1.0)
                ]
            } else {
                phases = mode.phases
            }
            startPhase()
        }
        .onReceive(timer) { _ in
            elapsed += 0.1
            if elapsed >= currentDuration {
                phase = (phase + 1) % phases.count
                startPhase()
            }
        }
    }
    
    private func startPhase() {
        breathText = phases[phase].text
        currentDuration = phases[phase].duration
        elapsed = 0.0
        withAnimation(.easeInOut(duration: currentDuration)) {
            scale = phases[phase].scale
        }
    }
}
