import SwiftUI

struct CustomBreathSetupScreen: View {
    let onNavigate: (SleepRelaxView.Screen) -> Void
    @Binding var inhale: Double
    @Binding var hold: Double
    @Binding var exhale: Double
    
    var body: some View {
        VStack(spacing: 40) {
            BackButton { onNavigate(.advancedBreathing) }
            
            Text("Custom Breathing Setup")
                .font(.title.bold())
                .foregroundColor(.white)
            
            VStack(spacing: 20) {
                SliderRow(title: "Inhale (sec)", value: $inhale, range: 1...10)
                SliderRow(title: "Hold (sec)", value: $hold, range: 0...10)
                SliderRow(title: "Exhale (sec)", value: $exhale, range: 1...10)
            }
            .padding(.horizontal, 40)
            
            Button("Apply") {
                onNavigate(.breathing) // Переход к дыханию с custom
            }
            .font(.title2.bold())
            .foregroundColor(Color(hex: "0A0033"))
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(RoundedRectangle(cornerRadius: 30).fill(Color(hex: "FFDDAA")))
            .padding(.horizontal, 50)
            
            Spacer()
        }
    }
}

struct SliderRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    
    var body: some View {
        HStack {
            Text(title).foregroundColor(.white)
            Spacer()
            Slider(value: $value, in: range, step: 1)
                .accentColor(Color(hex: "00E6C6"))
            Text("\(Int(value))").foregroundColor(.white)
        }
    }
}

struct PermissionsAppLunAirPushView: View {
    let onAccept: () -> Void
    let onReject: () -> Void
    
    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            
            ZStack {
                Image("push_bg")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .ignoresSafeArea()
                
                if isLandscape {
                    VStack {
                        Spacer()
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Allow notifications about bonuses and promos".uppercased())
                                    .font(.custom("Inter-Regular_Black", size: 24))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                
                                Text("Stay tuned with best offers from our casino")
                                    .font(.custom("Inter-Regular_Bold", size: 18))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            VStack {
                                Button(action: onAccept) {
                                    ZStack {
                                        Image("button_bg")
                                            .resizable()
                                            .frame(height: 55)
                                        
                                        Text("Yes, I Want Bonuses")
                                            .font(.custom("Inter-Regular_Black", size: 20))
                                            .foregroundColor(.black)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                                .frame(width: 350)
                                .padding(.top, 12)
                                
                                Button(action: onReject) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 50, style: .continuous)
                                            .fill(Color.white.opacity(0.17))
                                            .frame(height: 40)
                                        
                                        Text("SKIP")
                                            .font(.custom("Inter-Regular_Black", size: 16))
                                            .foregroundColor(.white.opacity(0.8))
                                            .multilineTextAlignment(.center)
                                    }
                                }
                                .frame(width: 320)
                            }
                        }
                        .padding(.bottom, 24)
                        .padding(.horizontal, 62)
                    }
                } else {
                    VStack(spacing: isLandscape ? 5 : 10) {
                        Spacer()
                        
                        Text("Allow notifications about bonuses and promos".uppercased())
                            .font(.custom("Inter-Regular_Black", size: 20))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Stay tuned with best offers from our casino")
                            .font(.custom("Inter-Regular_Bold", size: 15))
                            .foregroundColor(.white)
                            .padding(.horizontal, 52)
                            .multilineTextAlignment(.center)
                        
                        Button(action: onAccept) {
                            ZStack {
                                Image("button_bg")
                                    .resizable()
                                    .frame(height: 55)
                                
                                Text("Yes, I Want Bonuses")
                                    .font(.custom("Inter-Regular_Black", size: 20))
                                    .foregroundColor(.black)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .frame(width: 350)
                        .padding(.top, 12)
                        
                        Button(action: onReject) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 50, style: .continuous)
                                    .fill(Color.white.opacity(0.17))
                                    .frame(height: 40)
                                
                                Text("SKIP")
                                    .font(.custom("Inter-Regular_Black", size: 16))
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .frame(width: 320)
                        
                        Spacer()
                            .frame(height: isLandscape ? 30 : 50)
                    }
                    .padding(.horizontal, isLandscape ? 20 : 0)
                }
            }
        }
        .ignoresSafeArea()
    }
}
