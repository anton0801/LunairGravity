import Foundation
import Firebase
import FirebaseMessaging
import AppsFlyerLib
import Combine


protocol LunairDataRepository {
    func fetchOrganicAttribution(deepLinkInfo: [String: Any]) async throws -> [String: Any]
    func fetchConfigFromServer(payload: [String: Any]) async throws -> URL
}

class LunairDataRepositoryImpl: LunairDataRepository {
    private let appsFlyerLib: AppsFlyerLib
    
    init(appsFlyerLib: AppsFlyerLib = .shared()) {
        self.appsFlyerLib = appsFlyerLib
    }
    
    func fetchOrganicAttribution(deepLinkInfo: [String: Any]) async throws -> [String: Any] {
        let request = LunairRequestBuilder()
            .assignAppID(AppConstants.appsFlyerAppID)
            .assignDevKey(AppConstants.appsFlyerDevKey)
            .assignUID(appsFlyerLib.getAppsFlyerUID())
            .generate()
        
        guard let url = request else {
            throw NSError(domain: "AttributionError", code: 0, userInfo: nil)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "AttributionError", code: 1, userInfo: nil)
        }
        
        var combined = json
        for (key, value) in deepLinkInfo where combined[key] == nil {
            combined[key] = value
        }
        
        return combined
    }
    
    func fetchConfigFromServer(payload: [String: Any]) async throws -> URL {
        guard let serverURL = URL(string: "https://lunairgravity.com/config.php") else {
            throw NSError(domain: "ConfigError", code: 0, userInfo: nil)
        }
        
        var mutablePayload = payload
        mutablePayload["os"] = "iOS"
        mutablePayload["af_id"] = appsFlyerLib.getAppsFlyerUID()
        mutablePayload["bundle_id"] = "com.lunairgravity.LunairGravity"
        mutablePayload["firebase_project_id"] = FirebaseApp.app()?.options.gcmSenderID
        mutablePayload["store_id"] = "id\(AppConstants.appsFlyerAppID)"
        mutablePayload["push_token"] = UserDefaults.standard.string(forKey: "fcm_token") ?? Messaging.messaging().fcmToken
        mutablePayload["locale"] = Locale.preferredLanguages.first?.prefix(2).uppercased() ?? "EN"
        
        guard let jsonBody = try? JSONSerialization.data(withJSONObject: mutablePayload) else {
            throw NSError(domain: "ConfigError", code: 1, userInfo: nil)
        }
        
        var request = URLRequest(url: serverURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonBody
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let ok = obj["ok"] as? Bool, ok,
              let urlStr = obj["url"] as? String,
              let finalURL = URL(string: urlStr) else {
            throw NSError(domain: "ConfigError", code: 2, userInfo: nil)
        }
        
        return finalURL
    }
}
