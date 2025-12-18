import Foundation

struct AssessCurrentGravityUseCase {
    let repository: LunairStorageRepository
    
    func execute(attributionInfo: [String: Any], firstTimeOpening: Bool, planURL: URL?, tempURL: String?) -> LunairPhase {
        if attributionInfo.isEmpty {
            return .grounded
        }
        
        if repository.getGravityMode() == "Legacy" {
            return .grounded
        }
        
        if firstTimeOpening && (attributionInfo["af_status"] as? String == "Organic") {
            return .levitating
        }
        
        if let temp = tempURL, let url = URL(string: temp), planURL == nil {
            return .orbiting
        }
        
        return .levitating
    }
}

struct ShouldPromptForNotificationsUseCase {
    let repository: LunairStorageRepository
    
    func execute() -> Bool {
        guard !repository.getAcceptedNotifications(),
              !repository.getSystemCloseNotifications() else {
            return false
        }
        
        if let last = repository.getLastNotificationAsk(),
           Date().timeIntervalSince(last) < 259200 {
            return false
        }
        return true
    }
}

struct InitiateFirstGravityUseCase {
    func execute() async {
        try? await Task.sleep(nanoseconds: 5_000_000_000)
    }
}

struct SwitchToGroundedModeUseCase {
    let repository: LunairStorageRepository
    
    func execute() {
        repository.setGravityMode("Legacy")
        repository.setHasRunBefore()
    }
}

struct LoadSavedGravityUseCase {
    let repository: LunairStorageRepository
    
    func execute() -> URL? {
        repository.getSavedGravity()
    }
}

struct StoreSuccessfulGravityUseCase {
    let repository: LunairStorageRepository
    
    func execute(url: String) {
        repository.saveGravity(url)
        repository.setGravityMode("Active")
        repository.setHasRunBefore()
    }
}


struct AssessCurrentBalanceUseCase {
    let repository: LunairStorageRepository
   
    func execute(attributionInfo: [String: Any], firstTimeOpening: Bool, planURL: URL?, tempURL: String?) -> LunairPhase {
        if attributionInfo.isEmpty {
            return .grounded
        }
        
        if repository.getGravityMode() == "Legacy" {
            return .grounded
        }
        
        if firstTimeOpening && (attributionInfo["af_status"] as? String == "Organic") {
            return .levitating
        }
        
        if let temp = tempURL, let url = URL(string: temp), planURL == nil {
            return .orbiting
        }
        
        return .levitating
    }
}
