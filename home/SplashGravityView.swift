import SwiftUI

struct SplashGravityView: View {
    
    @StateObject private var viewModel = LunairGravityViewModel()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if viewModel.currentLunairPhase == .levitating || viewModel.showPermissionScreen {
                LunAirSplashView()
            }
            
            CurrentActiveViewAssociatedToState(viewModel: viewModel)
                .opacity(viewModel.showPermissionScreen ? 0 : 1)
            
            if viewModel.showPermissionScreen {
                PermissionsAppLunAirPushView(
                    onAccept: viewModel.userAllowedPermission,
                    onReject: viewModel.userSkippedPermission
                )
            }
        }
        .preferredColorScheme(.dark)
    }
}



