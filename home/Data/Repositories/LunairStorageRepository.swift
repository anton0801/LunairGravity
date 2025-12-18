import Foundation
import Firebase
import FirebaseMessaging


protocol LunairStorageRepository {
    var isFirstRun: Bool { get }
    func getSavedGravity() -> URL?
    func saveGravity(_ url: String)
    func setGravityMode(_ mode: String)
    func setHasRunBefore()
    func getGravityMode() -> String?
    func setLastNotificationAsk(_ date: Date)
    func setAcceptedNotifications(_ granted: Bool)
    func setSystemCloseNotifications(_ bool: Bool)
    func getAcceptedNotifications() -> Bool
    func getSystemCloseNotifications() -> Bool
    func getLastNotificationAsk() -> Date?
    func getFCMToken() -> String?
}

class LunairStorageRepositoryImpl: LunairStorageRepository {
    private let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    var isFirstRun: Bool {
        !userDefaults.bool(forKey: "hasLaunchedBefore")
    }
    
    func getSavedGravity() -> URL? {
        if let saved = userDefaults.string(forKey: "stored_config"),
           let url = URL(string: saved) {
            return url
        }
        return nil
    }
    
    func saveGravity(_ url: String) {
        userDefaults.set(url, forKey: "stored_config")
    }
    
    func setGravityMode(_ mode: String) {
        userDefaults.set(mode, forKey: "app_state")
    }
    
    func setHasRunBefore() {
        userDefaults.set(true, forKey: "hasLaunchedBefore")
    }
    
    func getGravityMode() -> String? {
        userDefaults.string(forKey: "app_state")
    }
    
    func setLastNotificationAsk(_ date: Date) {
        userDefaults.set(date, forKey: "last_perm_request")
    }
    
    func setAcceptedNotifications(_ granted: Bool) {
        userDefaults.set(granted, forKey: "perms_accepted")
    }
    
    func setSystemCloseNotifications(_ bool: Bool) {
        userDefaults.set(bool, forKey: "perms_denied")
    }
    
    func getAcceptedNotifications() -> Bool {
        userDefaults.bool(forKey: "perms_accepted")
    }
    
    func getSystemCloseNotifications() -> Bool {
        userDefaults.bool(forKey: "perms_denied")
    }
    
    func getLastNotificationAsk() -> Date? {
        userDefaults.object(forKey: "last_perm_request") as? Date
    }
    
    func getFCMToken() -> String? {
        userDefaults.string(forKey: "fcm_token") ?? Messaging.messaging().fcmToken
    }
}
