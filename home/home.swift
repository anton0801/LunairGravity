
import SwiftUI
import Combine

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

struct SleepRelaxView: View {
    @AppStorage("selectedTheme") private var selectedTheme = 0
    @AppStorage("remindMe") private var remindMe = true
    @AppStorage("vibration") private var vibration = false
    @AppStorage("autoBreath") private var autoBreath = true

    @State private var gradientColors: [Color] = themes[0]
    @State private var currentScreen: Screen = .main
    @State private var screenOpacity = 1.0

    enum Screen { case main, breathing, sounds, sleepTimer, settings }

    private var navigateTo: (Screen) -> Void {
        { screen in
            withAnimation(.easeInOut(duration: 0.6)) {
                currentScreen = screen
            }
        }
    }

    private var changeTheme: (Int) -> Void {
        { index in
            withAnimation(.easeInOut(duration: 0.6)) {
                gradientColors = themes[index]
                selectedTheme = index
            }
        }
    }

    init() {
        _gradientColors = State(initialValue: themes[selectedTheme])
    }

    var body: some View {
        ZStack {
            AppBackground(gradientColors: gradientColors)

            if currentScreen == .main {
                MainScreen(onNavigate: navigateTo)
            } else if currentScreen == .breathing {
                BreathingScreen(onNavigate: navigateTo)
            } else if currentScreen == .sounds {
                SoundsScreen(onNavigate: navigateTo)
            } else if currentScreen == .sleepTimer {
                SleepTimerScreen(onNavigate: navigateTo, screenOpacity: $screenOpacity)
            } else if currentScreen == .settings {
                SettingsScreen(
                    onNavigate: navigateTo,
                    changeTheme: changeTheme,
                    selectedTheme: selectedTheme,
                    remindMe: $remindMe,
                    vibration: $vibration,
                    autoBreath: $autoBreath
                )
            }
        }
        .animation(.easeInOut(duration: 0.6), value: currentScreen)
        .statusBar(hidden: true)
    }
}

// Остальные экраны — полностью рабочие

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
                QuickModeBubble(title: "Sleep", image: "moon.stars.fill") { onNavigate(.sounds) }
                QuickModeBubble(title: "Waves", image: "waveform") { onNavigate(.sounds) }
            }

            Spacer()
            Spacer()
        }
    }
}

struct BreathingScreen: View {
    let onNavigate: (SleepRelaxView.Screen) -> Void
    @State private var scale: CGFloat = 1.0
    @State private var breathText = "Inhale..."
    @State private var phase = 0

    let timer = Timer.publish(every: 4, on: .main, in: .common).autoconnect()

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

            Button { onNavigate(.sounds) } label: {
                Circle()
                    .fill(Color(hex: "FFDDAA"))
                    .frame(width: 80, height: 80)
                    .overlay(Image(systemName: "checkmark").font(.largeTitle).foregroundColor(Color(hex: "0A0033")))
                    .shadow(color: Color(hex: "FFDDAA").opacity(0.8), radius: 30)
            }
            .padding(.bottom, 100)
        }
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 3.8)) {
                if phase == 0 { scale = 2.0; breathText = "Inhale..." }
                else if phase == 1 { scale = 2.0; breathText = "Hold..." }
                else { scale = 1.0; breathText = "Exhale..." }
                phase = (phase + 1) % 3
            }
        }
    }
}

struct SoundsScreen: View {
    let onNavigate: (SleepRelaxView.Screen) -> Void
    let sounds = ["Rain", "Ocean", "Fireplace", "Wind", "Silence", "Lullaby"]
    @State private var selected: String?

    var body: some View {
        VStack {
            BackButton { onNavigate(.main) }

            Spacer()

            Text("Choose atmosphere")
                .font(.title.bold())
                .foregroundColor(.white)
                .padding(.horizontal, 40)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 30), count: 3), spacing: 35) {
                ForEach(sounds, id: \.self) { s in
                    Button { selected = s } label: {
                        Text(s)
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 100, height: 100)
                            .background(Circle().fill(selected == s ? Color(hex: "00E6C6") : Color.white.opacity(0.15))
                                .shadow(color: selected == s ? Color(hex: "00E6C6").opacity(0.8) : .clear, radius: 30))
                    }
                }
            }
            .padding(.horizontal, 30)

            BubbleButton(title: "Start atmosphere") { onNavigate(.sleepTimer) }
                .padding(.top, 60)

            Spacer()
        }
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

struct SleepTimerScreen: View {
    let onNavigate: (SleepRelaxView.Screen) -> Void
    @Binding var screenOpacity: Double

    @State private var selectedMinutes = 30
    @State private var remainingSeconds = 0
    @State private var isRunning = false

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            // Заголовок и кнопка на одной линии
            HStack {
                BackButton { onNavigate(.main) }
                Spacer()
                Text("Sleep Timer")
                    .font(.title.bold())
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.top, 60)
            .padding(.horizontal, 30)

            Spacer()

            ZStack {
                Circle()
                    .fill(Color(hex: "FFDDAA").opacity(0.3))
                    .frame(width: 240, height: 240)
                    .blur(radius: 50)

                Text(isRunning ? timeString(remainingSeconds) : "Choose time")
                    .font(.system(size: isRunning ? 72 : 36, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 60)

            VStack(spacing: 40) {
                HStack(spacing: 60) {
                    TimerBubble(minutes: 30, selected: $selectedMinutes, running: $isRunning, seconds: $remainingSeconds, opacity: $screenOpacity)
                    TimerBubble(minutes: 45, selected: $selectedMinutes, running: $isRunning, seconds: $remainingSeconds, opacity: $screenOpacity)
                }
                HStack(spacing: 60) {
                    TimerBubble(minutes: 60, selected: $selectedMinutes, running: $isRunning, seconds: $remainingSeconds, opacity: $screenOpacity)
                    Circle()
                        .fill(Color(hex: "FFDDAA").opacity(0.6))
                        .frame(width: 100, height: 100)
                        .overlay(Image(systemName: "clock").font(.title).foregroundColor(.white.opacity(0.9)))
                }
            }
            .padding(.bottom, 60)

            Spacer()

            if isRunning {
                Button {
                    withAnimation {
                        isRunning = false
                        remainingSeconds = 0
                        screenOpacity = 1.0
                    }
                } label: {
                    Text("Stop timer")
                        .font(.title2.bold())
                        .foregroundColor(Color(hex: "0A0033"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 80)
                        .background(RoundedRectangle(cornerRadius: 40).fill(Color(hex: "FFDDAA")))
                        .shadow(color: Color(hex: "FFDDAA").opacity(0.8), radius: 30)
                }
                .padding(.horizontal, 50)
                .padding(.bottom, 40)
            }

            Spacer(minLength: 80)
        }
        .onReceive(timer) { _ in
            if isRunning && remainingSeconds > 0 {
                remainingSeconds -= 1
            }
            if remainingSeconds <= 0 && isRunning {
                isRunning = false
                withAnimation { screenOpacity = 1.0 }
            }
        }
    }

    private func timeString(_ secs: Int) -> String {
        let m = secs / 60
        let s = secs % 60
        return String(format: "%02d:%02d", m, s)
    }
}

struct SettingsScreen: View {
    let onNavigate: (SleepRelaxView.Screen) -> Void
    let changeTheme: (Int) -> Void
    let selectedTheme: Int

    @Binding var remindMe: Bool
    @Binding var vibration: Bool
    @Binding var autoBreath: Bool

    var body: some View {
        VStack {
            BackButton { onNavigate(.main) }

            Spacer()

            Text("Settings")
                .font(.title.bold())
                .foregroundColor(.white)

            VStack(spacing: 45) {
                ToggleRow(title: "Sleep reminder", isOn: $remindMe)
                ToggleRow(title: "Vibration", isOn: $vibration)
                ToggleRow(title: "Auto-start breathing", isOn: $autoBreath)

                Text("Themes")
                    .foregroundColor(Color(hex: "BFDFFF"))
                    .padding(.top, 20)

                HStack(spacing: 50) {
                    ThemeBubble(index: 0, selectedTheme: selectedTheme, changeTheme: changeTheme)
                    ThemeBubble(index: 1, selectedTheme: selectedTheme, changeTheme: changeTheme)
                    ThemeBubble(index: 2, selectedTheme: selectedTheme, changeTheme: changeTheme)
                }
            }
            .padding(.horizontal, 40)

            Spacer()
        }
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

@main
struct SleepRelaxApp: App {
    var body: some Scene {
        WindowGroup {
            SleepRelaxView()
        }
    }
}
