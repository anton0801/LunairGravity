
import SwiftUI

struct AdvancedBreathingScreen: View {
    let onNavigate: (SleepRelaxView.Screen) -> Void
    let onSelectMode: (BreathingMode) -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            BackButton { onNavigate(.main) }
            
            Text("Advanced Breathing Modes")
                .font(.title.bold())
                .foregroundColor(.white)
            
            VStack(spacing: 20) {
                ModeButton(title: "4-7-8 Breathing", description: "For stress relief") {
                    onSelectMode(.fourSevenEight)
                }
                ModeButton(title: "Box Breathing", description: "For focus") {
                    onSelectMode(.box)
                }
                ModeButton(title: "Alternate Nostril", description: "For balance") {
                    onSelectMode(.alternateNostril)
                }
                ModeButton(title: "Custom Breathing", description: "Personalized") {
                    onNavigate(.customBreathSetup)
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

struct ModeButton: View {
    let title: String
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading) {
                    Text(title).font(.title3.bold()).foregroundColor(.white)
                    Text(description).font(.caption).foregroundColor(.white.opacity(0.8))
                }
                Spacer()
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 20).fill(.white.opacity(0.2)))
        }
    }
}
