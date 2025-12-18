import Foundation
import AppsFlyerLib
import Network
import Firebase
import FirebaseMessaging
import Combine
import SwiftUI

struct LunairRequestBuilder {
    private var appID = ""
    private var devKey = ""
    private var uid = ""
    private let endpoint = "https://gcdsdk.appsflyer.com/install_data/v4.0/"
    
    func assignAppID(_ id: String) -> Self { duplicate(appID: id) }
    func assignDevKey(_ key: String) -> Self { duplicate(devKey: key) }
    func assignUID(_ id: String) -> Self { duplicate(uid: id) }
    
    func generate() -> URL? {
        guard !appID.isEmpty, !devKey.isEmpty, !uid.isEmpty else { return nil }
        var parts = URLComponents(string: endpoint + "id" + appID)!
        parts.queryItems = [
            URLQueryItem(name: "devkey", value: devKey),
            URLQueryItem(name: "device_id", value: uid)
        ]
        return parts.url
    }
    
    private func duplicate(appID: String = "", devKey: String = "", uid: String = "") -> Self {
        var instance = self
        if !appID.isEmpty { instance.appID = appID }
        if !devKey.isEmpty { instance.devKey = devKey }
        if !uid.isEmpty { instance.uid = uid }
        return instance
    }
}

struct HandlePermissionSkipUseCase {
    let repository: LunairStorageRepository
    
    func execute() {
        repository.setLastNotificationAsk(Date())
    }
}

struct HandlePermissionGrantUseCase {
    let repository: LunairStorageRepository
    
    func execute(granted: Bool) {
        repository.setAcceptedNotifications(granted)
        if !granted {
            repository.setSystemCloseNotifications(true)
        }
    }
}

struct FetchOrganicAttributionUseCase {
    let repository: LunairDataRepository
    
    func execute(deepLinkInfo: [String: Any]) async throws -> [String: Any] {
        try await repository.fetchOrganicAttribution(deepLinkInfo: deepLinkInfo)
    }
}

struct FetchConfigUseCase {
    let repository: LunairDataRepository
    
    func execute(attributionInfo: [String: Any]) async throws -> URL {
        try await repository.fetchConfigFromServer(payload: attributionInfo)
    }
}

enum LunairPhase { case levitating, orbiting, grounded, lostSignal }

final class LunairGravityViewModel: ObservableObject {
    @Published var currentLunairPhase: LunairPhase = .levitating
    @Published var gravityURL: URL?
    @Published var showPermissionScreen = false
    
    private var attributionInfo: [String: Any] = [:]
    private var deepLinkInfo: [String: Any] = [:]
    private var subscriptions = Set<AnyCancellable>()
    private let connectivityChecker = NWPathMonitor()
    private let storageRepository: LunairStorageRepository
    private let dataRepository: LunairDataRepository
    
    init(storageRepository: LunairStorageRepository = LunairStorageRepositoryImpl(), dataRepository: LunairDataRepository = LunairDataRepositoryImpl()) {
        self.storageRepository = storageRepository
        self.dataRepository = dataRepository
        setupNotificationPublishers()
        observeNetworkStatus()
    }
    
    deinit {
        connectivityChecker.cancel()
    }
    
    private func isDateValid() -> Bool {
        let currentCalendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.year = 2025
        dateComponents.month = 12
        dateComponents.day = 20
        if let comparisonDate = currentCalendar.date(from: dateComponents) {
            return Date() >= comparisonDate
        }
        return false
    }
    
    private func setupNotificationPublishers() {
        NotificationCenter.default
            .publisher(for: Notification.Name("ConversionDataReceived"))
            .compactMap { $0.userInfo?["conversionData"] as? [String: Any] }
            .sink { [weak self] info in
                self?.attributionInfo = info
                self?.determineCurrentPhase()
            }
            .store(in: &subscriptions)
        
        NotificationCenter.default
            .publisher(for: Notification.Name("deeplink_values"))
            .compactMap { $0.userInfo?["deeplinksData"] as? [String: Any] }
            .sink { [weak self] info in
                self?.deepLinkInfo = info
            }
            .store(in: &subscriptions)
    }
    
    
    private func fetchConfig() {
        let useCase = FetchConfigUseCase(repository: dataRepository)
        Task { [weak self] in
            do {
                let finalURL = try await useCase.execute(attributionInfo: self?.attributionInfo ?? [:])
                let urlStr = finalURL.absoluteString
                await MainActor.run {
                    self?.storeSuccessfulGravity(urlStr, finalURL: finalURL)
                }
            } catch {
                self?.loadSavedGravity()
            }
        }
    }
    
    func userSkippedPermission() {
        let useCase = HandlePermissionSkipUseCase(repository: storageRepository)
        useCase.execute()
        showPermissionScreen = false
        fetchConfig()
    }
    
    func userAllowedPermission() {
        let useCase = HandlePermissionGrantUseCase(repository: storageRepository)
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
            DispatchQueue.main.async {
                useCase.execute(granted: granted)
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                self?.showPermissionScreen = false
                if self?.gravityURL != nil {
                    self?.setPhase(to: .orbiting)
                } else {
                    self?.fetchConfig()
                }
            }
        }
    }
    
    private func initiateFirstGravity() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            Task { [weak self] in
                await self?.fetchOrganicAttribution()
            }
        }
    }
    private func loadSavedGravity() {
        let useCase = LoadSavedGravityUseCase(repository: storageRepository)
        if let url = useCase.execute() {
            gravityURL = url
            setPhase(to: .orbiting)
        } else {
            switchToGroundedMode()
        }
    }
    
    private func switchToGroundedMode() {
        let useCase = SwitchToGroundedModeUseCase(repository: storageRepository)
        useCase.execute()
        setPhase(to: .grounded)
    }
    
    private func storeSuccessfulGravity(_ url: String, finalURL: URL) {
        let useCase = StoreSuccessfulGravityUseCase(repository: storageRepository)
        useCase.execute(url: url)
        let checker = ShouldPromptForNotificationsUseCase(repository: storageRepository)
        if checker.execute() {
            gravityURL = finalURL
            showPermissionScreen = true
        } else {
            gravityURL = finalURL
            setPhase(to: .orbiting)
        }
    }
    
    private func setPhase(to phase: LunairPhase) {
        DispatchQueue.main.async {
            self.currentLunairPhase = phase
        }
    }
    
    private func fetchOrganicAttribution() async {
        do {
            let useCase = FetchOrganicAttributionUseCase(repository: dataRepository)
            let combined = try await useCase.execute(deepLinkInfo: deepLinkInfo)
            await MainActor.run {
                self.attributionInfo = combined
                self.fetchConfig()
            }
        } catch {
            switchToGroundedMode()
        }
    }
    
    private func observeNetworkStatus() {
        connectivityChecker.pathUpdateHandler = { [weak self] path in
            if path.status != .satisfied {
                DispatchQueue.main.async {
                    if self?.storageRepository.getGravityMode() == "Active" {
                        self?.setPhase(to: .lostSignal)
                    } else {
                        self?.switchToGroundedMode()
                    }
                }
            }
        }
        connectivityChecker.start(queue: .global())
    }
    
    @objc private func determineCurrentPhase() {
        if !isDateValid() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.switchToGroundedMode()
            }
            return
        }
        
        if attributionInfo.isEmpty {
            loadSavedGravity()
            return
        }
        
        if storageRepository.getGravityMode() == "Legacy" {
            switchToGroundedMode()
            return
        }
        
        let useCase = AssessCurrentBalanceUseCase(repository: storageRepository)
        let phase = useCase.execute(attributionInfo: attributionInfo, firstTimeOpening: storageRepository.isFirstRun, planURL: gravityURL, tempURL: UserDefaults.standard.string(forKey: "temp_url"))
        
        if phase == .levitating && storageRepository.isFirstRun {
            initiateFirstGravity()
            return
        }
        
        if let urlStr = UserDefaults.standard.string(forKey: "temp_url"),
           let url = URL(string: urlStr) {
            gravityURL = url
            setPhase(to: .orbiting)
            return
        }
        
        if gravityURL == nil {
            let promptUseCase = ShouldPromptForNotificationsUseCase(repository: storageRepository)
            if promptUseCase.execute() {
                showPermissionScreen = true
            } else {
                fetchConfig()
            }
        }
    }
   
}
