import Foundation
import Firebase
import FirebaseMessaging
import AppsFlyerLib



protocol LunairConfigRepository {
    func getLocale() -> String
    func getBundleID() -> String
    func getFirebaseProjectID() -> String?
    func getStoreID() -> String
    func getAppsFlyerUID() -> String
}

class LunairConfigRepositoryImpl: LunairConfigRepository {
    func getLocale() -> String {
        Locale.preferredLanguages.first?.prefix(2).uppercased() ?? "EN"
    }
    
    func getBundleID() -> String {
        "com.lunnaiirair.Lunair"
    }
    
    func getFirebaseProjectID() -> String? {
        FirebaseApp.app()?.options.gcmSenderID
    }
    
    func getStoreID() -> String {
        "id\(AppConstants.appsFlyerAppID)"
    }
    
    func getAppsFlyerUID() -> String {
        AppsFlyerLib.shared().getAppsFlyerUID()
    }
}
