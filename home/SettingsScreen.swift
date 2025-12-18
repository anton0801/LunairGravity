import SwiftUI

struct SettingsScreen: View {
    let onNavigate: (SleepRelaxView.Screen) -> Void
    let changeTheme: (Int) -> Void
    let selectedTheme: Int

    @Binding var remindMe: Bool
    @Binding var vibration: Bool
    @Binding var autoBreath: Bool

    var body: some View {
        VStack {
            HStack {
                BackButton { onNavigate(.main) }
                Text("Settings")
                    .font(.title.bold())
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 32)


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
                
                Button {
                    UIApplication.shared.open(URL(string: "https://lunairgravity.com/privacy-policy.html")!)
                } label: {
                    HStack {
                        Text("Privacy Policy")
                            .foregroundColor(.white)
                            .font(.title3)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 40)

            Spacer()
        }
    }
}


struct CurrentActiveViewAssociatedToState: View {
    @ObservedObject var viewModel: LunairGravityViewModel
    
    var body: some View {
        Group {
            switch viewModel.currentLunairPhase {
            case .levitating:
                EmptyView()
                
            case .orbiting:
                if viewModel.gravityURL != nil {
                    LunairMainView()
                } else {
                    SleepRelaxView()
                }
                
            case .grounded:
                SleepRelaxView()
                
            case .lostSignal:
                LunAirFailConnectionInternetView()
            }
        }
    }
}
