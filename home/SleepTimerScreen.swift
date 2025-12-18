import SwiftUI
import Combine

struct SleepTimerScreen: View {
    let onNavigate: (SleepRelaxView.Screen) -> Void
    @Binding var screenOpacity: Double

    @State private var selectedMinutes = 30
    @State private var remainingSeconds = 0
    @State private var isRunning = false

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    let onSessionComplete: (Int) -> Void

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
                        onSessionComplete(selectedMinutes * 60) // Логируем длительность
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
                onSessionComplete(selectedMinutes * 60) // Логируем при завершении
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
