import SwiftUI
import Combine
import Firebase
import UserNotifications
import AppsFlyerLib
import AppTrackingTransparency

struct AppConstants {
    static let appsFlyerAppID = "6756009199"
    static let appsFlyerDevKey = "BEos7iyGR5Hyw8ihhfk3xj"
}

class GravityPlusAppDelegate: UIResponder, UIApplicationDelegate, AppsFlyerLibDelegate, MessagingDelegate, UNUserNotificationCenterDelegate, DeepLinkDelegate {
    
    private var zenLinkData: [AnyHashable: Any] = [:]
    private var zenConversionInfo: [AnyHashable: Any] = [:]
    
    private let attributionSentFlag = "trackingDataSent"
    
    private var linkMergeTimer: Timer?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        UIApplication.shared.registerForRemoteNotifications()
        AppsFlyerLib.shared().appsFlyerDevKey = AppConstants.appsFlyerDevKey
        AppsFlyerLib.shared().appleAppID = AppConstants.appsFlyerAppID
        AppsFlyerLib.shared().delegate = self
        AppsFlyerLib.shared().deepLinkDelegate = self
        
        if let pushPayload = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            extractZenFromPush(pushPayload)
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(activateZenTracking),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    @objc private func activateZenTracking() {
        if #available(iOS 14.0, *) {
            AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
            ATTrackingManager.requestTrackingAuthorization { _ in
                DispatchQueue.main.async {
                    AppsFlyerLib.shared().start()
                }
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        extractZenFromPush(response.notification.request.content.userInfo)
        completionHandler()
    }
    
    private func startLinkMergeTimer() {
        linkMergeTimer?.invalidate()
        linkMergeTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
            self?.dispatchMergedData()
        }
    }
    
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        extractZenFromPush(userInfo)
        completionHandler(.newData)
    }
    
    
    private func extractZenFromPush(_ payload: [AnyHashable: Any]) {
        var extractedURL: String?
        if let directURL = payload["url"] as? String {
            extractedURL = directURL
        } else if let nestedData = payload["data"] as? [String: Any],
                  let nestedURL = nestedData["url"] as? String {
            extractedURL = nestedURL
        }
        if let validURL = extractedURL {
            UserDefaults.standard.set(validURL, forKey: "temp_url")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                NotificationCenter.default.post(
                    name: NSNotification.Name("LoadTempURL"),
                    object: nil,
                    userInfo: ["temp_url": validURL]
                )
            }
        }
    }
    
    func onConversionDataSuccess(_ data: [AnyHashable: Any]) {
        zenConversionInfo = data
        startLinkMergeTimer()
        if !zenLinkData.isEmpty {
            dispatchMergedData()
        }
    }
    
    func didResolveDeepLink(_ result: DeepLinkResult) {
        guard case .found = result.status,
              let resolvedLink = result.deepLink else { return }
        guard !UserDefaults.standard.bool(forKey: attributionSentFlag) else { return }
        zenLinkData = resolvedLink.clickEvent
        NotificationCenter.default.post(name: Notification.Name("deeplink_values"), object: nil, userInfo: ["deeplinksData": zenLinkData])
        linkMergeTimer?.invalidate()
        if !zenConversionInfo.isEmpty {
            dispatchMergedData()
        }
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        messaging.token { [weak self] token, error in
            guard error == nil, let validToken = token else { return }
            UserDefaults.standard.set(validToken, forKey: "fcm_token")
            UserDefaults.standard.set(validToken, forKey: "push_token")
        }
    }
    
    
    func dispatchData(info: [AnyHashable: Any]) {
        NotificationCenter.default.post(
            name: Notification.Name("ConversionDataReceived"),
            object: nil,
            userInfo: ["conversionData": info]
        )
    }
    
    func onConversionDataFail(_ error: Error) {
        dispatchData(info: [:])
        print("Apps errror \(error.localizedDescription)")
    }
    
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let notificationPayload = notification.request.content.userInfo
        extractZenFromPush(notificationPayload)
        completionHandler([.banner, .sound])
    }
    
    private func dispatchMergedData() {
        var mergedInfo = zenConversionInfo
        for (key, value) in zenLinkData {
            if mergedInfo[key] == nil {
                mergedInfo[key] = value
            }
        }
        dispatchData(info: mergedInfo)
        UserDefaults.standard.set(true, forKey: attributionSentFlag)
    }
    
}
