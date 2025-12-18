import SwiftUI
import Combine

struct SleepRelaxView: View {
    @AppStorage("selectedTheme") private var selectedTheme = 0
    @AppStorage("remindMe") private var remindMe = true
    @AppStorage("vibration") private var vibration = false
    @AppStorage("autoBreath") private var autoBreath = true
    
    // Для кастомного дыхания
    @AppStorage("customInhale") private var customInhale: Double = 4.0
    @AppStorage("customHold") private var customHold: Double = 4.0
    @AppStorage("customExhale") private var customExhale: Double = 4.0
    
    // Для статистики (UserDefaults для простоты, массив дат сессий)
    @AppStorage("breathingSessions") private var breathingSessionsData: Data = Data()
    @AppStorage("timerSessionsData") private var timerSessionsData: Data = Data()

    @State private var gradientColors: [Color] = themes[0]
    @State private var currentScreen: Screen = .main
    @State private var screenOpacity = 1.0
    
    // Для передачи параметров в BreathingScreen
    @State private var selectedBreathingMode: BreathingMode = .basic

    enum Screen { case main, breathing, sleepTimer, settings, advancedBreathing, customBreathSetup, progress }

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
                BreathingScreen(onNavigate: navigateTo, mode: selectedBreathingMode, onSessionComplete: logBreathingSession)
            } else if currentScreen == .sleepTimer {
                SleepTimerScreen(onNavigate: navigateTo, screenOpacity: $screenOpacity, onSessionComplete: logTimerSession)
            } else if currentScreen == .settings {
                SettingsScreen(
                    onNavigate: navigateTo,
                    changeTheme: changeTheme,
                    selectedTheme: selectedTheme,
                    remindMe: $remindMe,
                    vibration: $vibration,
                    autoBreath: $autoBreath
                )
            } else if currentScreen == .advancedBreathing {
                AdvancedBreathingScreen(onNavigate: navigateTo, onSelectMode: { mode in
                    selectedBreathingMode = mode
                    navigateTo(.breathing)
                })
            } else if currentScreen == .customBreathSetup {
                CustomBreathSetupScreen(onNavigate: navigateTo, inhale: $customInhale, hold: $customHold, exhale: $customExhale)
            } else if currentScreen == .progress {
                ProgressDashboard(onNavigate: navigateTo, breathingSessions: loadBreathingSessions(), timerSessions: loadTimerSessions())
            }
        }
        .animation(.easeInOut(duration: 0.6), value: currentScreen)
        .statusBar(hidden: true)
    }
    
    // Функции для логирования сессий
    private func logBreathingSession() {
        var sessions = loadBreathingSessions()
        sessions.append(Date())
        saveBreathingSessions(sessions)
    }
    
    private func logTimerSession(duration: Int) {
        var sessions = loadTimerSessions()
        sessions.append(TimerSession(date: Date(), duration: duration))
        saveTimerSessions(sessions)
    }
    
    private func loadBreathingSessions() -> [Date] {
        guard let sessions = try? JSONDecoder().decode([Date].self, from: breathingSessionsData) else { return [] }
        return sessions
    }
    
    private func saveBreathingSessions(_ sessions: [Date]) {
        if let data = try? JSONEncoder().encode(sessions) {
            breathingSessionsData = data
        }
    }
    
    private func loadTimerSessions() -> [TimerSession] {
        guard let sessions = try? JSONDecoder().decode([TimerSession].self, from: timerSessionsData) else { return [] }
        return sessions
    }
    
    private func saveTimerSessions(_ sessions: [TimerSession]) {
        if let data = try? JSONEncoder().encode(sessions) {
            timerSessionsData = data
        }
    }
}


struct LunAirFailConnectionInternetView: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image("fail_internet_back")
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
                
                Image("fail_internet")
                    .resizable()
                    .frame(width: 270, height: 210)
            }
        }
        .ignoresSafeArea()
    }
}
