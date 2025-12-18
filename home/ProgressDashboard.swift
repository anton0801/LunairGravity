import SwiftUI
import WebKit
import Combine
import Charts

struct ProgressDashboard: View {
    let onNavigate: (SleepRelaxView.Screen) -> Void
    let breathingSessions: [Date]
    let timerSessions: [TimerSession]
    
    var body: some View {
        VStack(spacing: 20) {
            BackButton { onNavigate(.main) }
            
            Text("Progress Dashboard")
                .font(.title.bold())
                .foregroundColor(.white)
            
            ScrollView {
                VStack(spacing: 30) {
                    StatText(title: "Breathing Sessions This Week", value: "\(sessionsThisWeek(breathingSessions))")
                    StatText(title: "Breathing Sessions This Month", value: "\(sessionsThisMonth(breathingSessions))")
                    
                    StatText(title: "Timer Sessions This Week", value: "\(sessionsThisWeek(timerSessions.map { $0.date }))")
                    StatText(title: "Timer Sessions This Month", value: "\(sessionsThisMonth(timerSessions.map { $0.date }))")
                    
                    StatText(title: "Average Sleep Time", value: "\(averageSleepTime()) min")
                    
                    if !breathingSessions.isEmpty {
                        if timerSessions.count < 1 {
                            ChartView(title: "Breathing Sessions Over Time", dates: breathingSessions, values: [1.0, 2.0, 3.0, 4.0])
                        } else {
                            ChartView(title: "Breathing Sessions Over Time", dates: breathingSessions, values: timerSessions.map { Double($0.duration) })
                        }
                    }
                    
                    if !timerSessions.isEmpty {
                        ChartView(title: "Timer Durations", dates: timerSessions.map { $0.date }, values: timerSessions.map { Double($0.duration) / 60 })
                    }
                }
                .padding()
            }
            
            Spacer()
        }
    }
    
    private func sessionsThisWeek(_ dates: [Date]) -> Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return dates.filter { $0 > weekAgo }.count
    }
    
    private func sessionsThisMonth(_ dates: [Date]) -> Int {
        let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        return dates.filter { $0 > monthAgo }.count
    }
    
    private func averageSleepTime() -> Int {
        if timerSessions.isEmpty { return 0 }
        let total = timerSessions.reduce(0) { $0 + $1.duration }
        return total / timerSessions.count / 60 // в минутах
    }
}

struct ChartView: View {
    let title: String
    let dates: [Date]
    let values: [Double]?
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title).font(.headline).foregroundColor(.white)
            
            Chart {
                if let values = values {
                    ForEach(0..<dates.count, id: \.self) { i in
                        BarMark(
                            x: .value("Date", dates[i], unit: .day),
                            y: .value("Duration", values[i])
                        )
                    }
                } else {
                    ForEach(dates, id: \.self) { date in
                        PointMark(
                            x: .value("Date", date, unit: .day),
                            y: .value("Sessions", 1)
                        )
                    }
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day))
            }
            .foregroundColor(Color(hex: "00E6C6"))
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 15).fill(.white.opacity(0.15)))
    }
}

struct LunairMainView: View {
    
    @State private var currentGravityLink = ""
    
    var body: some View {
        ZStack {
            if let gravityLink = URL(string: currentGravityLink) {
                GravityHostView(gravityLink: gravityLink)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear(perform: configureGravityLink)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LoadTempUrl"))) { _ in
            if let tempGravity = UserDefaults.standard.string(forKey: "temp_url"), !tempGravity.isEmpty {
                currentGravityLink = tempGravity
                UserDefaults.standard.removeObject(forKey: "temp_url")
            }
        }
    }
    
    private func configureGravityLink() {
        let tempGravity = UserDefaults.standard.string(forKey: "temp_url")
        let storedGravity = UserDefaults.standard.string(forKey: "stored_config") ?? ""
        currentGravityLink = tempGravity ?? storedGravity
        
        if tempGravity != nil {
            UserDefaults.standard.removeObject(forKey: "temp_url")
        }
    }
}

struct GravityHostView: UIViewRepresentable {
    let gravityLink: URL
    
    @StateObject private var gravitySupervisor = GravitySupervisor()
    
    func makeCoordinator() -> GravityNavigationManager {
        GravityNavigationManager(supervisor: gravitySupervisor)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        gravitySupervisor.setupPrimaryView()
        gravitySupervisor.primaryGravityView.uiDelegate = context.coordinator
        gravitySupervisor.primaryGravityView.navigationDelegate = context.coordinator
        
        gravitySupervisor.loadStoredGravity()
        gravitySupervisor.primaryGravityView.load(URLRequest(url: gravityLink))
        
        return gravitySupervisor.primaryGravityView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

class GravitySupervisor: ObservableObject {
    @Published var primaryGravityView: WKWebView!
    
    private var subs = Set<AnyCancellable>()
    
    func setupPrimaryView() {
        let config = createGravityConfig()
        primaryGravityView = WKWebView(frame: .zero, configuration: config)
        applyGravitySettings(to: primaryGravityView)
    }
    
    private func createGravityConfig() -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        let prefs = WKPreferences()
        prefs.javaScriptEnabled = true
        prefs.javaScriptCanOpenWindowsAutomatically = true
        config.preferences = prefs
        
        let pagePrefs = WKWebpagePreferences()
        pagePrefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = pagePrefs
        
        return config
    }
    
    private func applyGravitySettings(to webView: WKWebView) {
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.bounces = false
        webView.scrollView.bouncesZoom = false
        webView.allowsBackForwardNavigationGestures = true
    }
    
    @Published var additionalGravityViews: [WKWebView] = []
    
    func loadStoredGravity() {
        guard let storedGravity = UserDefaults.standard.object(forKey: "preserved_grains") as? [String: [String: [HTTPCookiePropertyKey: AnyObject]]] else { return }
        
        let gravityStore = primaryGravityView.configuration.websiteDataStore.httpCookieStore
        let gravityItems = storedGravity.values.flatMap { $0.values }.compactMap {
            HTTPCookie(properties: $0 as [HTTPCookiePropertyKey: Any])
        }
        
        gravityItems.forEach { gravityStore.setCookie($0) }
    }
    
    func revertGravity(to url: URL? = nil) {
        if !additionalGravityViews.isEmpty {
            if let lastAdditional = additionalGravityViews.last {
                lastAdditional.removeFromSuperview()
                additionalGravityViews.removeLast()
            }
            
            if let targetURL = url {
                primaryGravityView.load(URLRequest(url: targetURL))
            }
        } else if primaryGravityView.canGoBack {
            primaryGravityView.goBack()
        }
    }
    
    func refreshGravity() {
        primaryGravityView.reload()
    }
}

class GravityNavigationManager: NSObject, WKNavigationDelegate, WKUIDelegate {
    
    private var redirectCount = 0
    
    init(supervisor: GravitySupervisor) {
        self.gravitySupervisor = supervisor
        super.init()
    }
    
    private var gravitySupervisor: GravitySupervisor
    
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for action: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard action.targetFrame == nil else { return nil }
        
        let newGravityView = WKWebView(frame: .zero, configuration: configuration)
        setupNewGravityView(newGravityView)
        attachGravityConstraints(newGravityView)
        
        gravitySupervisor.additionalGravityViews.append(newGravityView)
        
        let edgeSwipeRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(processEdgeSwipe))
        edgeSwipeRecognizer.edges = .left
        newGravityView.addGestureRecognizer(edgeSwipeRecognizer)
        
        func isValidRequest(_ request: URLRequest) -> Bool {
            guard let urlString = request.url?.absoluteString,
                  !urlString.isEmpty,
                  urlString != "about:blank" else { return false }
            return true
        }
        
        if isValidRequest(action.request) {
            newGravityView.load(action.request)
        }
        
        return newGravityView
    }
    
    private var lastKnownURL: URL?
    
    private let maxRedirectsPerMinute = 70
    
    func webView(_ webView: WKWebView,
                 didReceive challenge: URLAuthenticationChallenge,
                 completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let serverTrust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
    
    private func setupNewGravityView(_ webView: WKWebView) {
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.bounces = false
        webView.scrollView.bouncesZoom = false
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = self
        webView.uiDelegate = self
        gravitySupervisor.primaryGravityView.addSubview(webView)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let enhancementScript = """
        (function() {
            const vp = document.createElement('meta');
            vp.name = 'viewport';
            vp.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
            document.head.appendChild(vp);
            
            const rules = document.createElement('style');
            rules.textContent = 'body { touch-action: pan-x pan-y; } input, textarea { font-size: 16px !important; }';
            document.head.appendChild(rules);
            
            document.addEventListener('gesturestart', e => e.preventDefault());
            document.addEventListener('gesturechange', e => e.preventDefault());
        })();
        """
        
        webView.evaluateJavaScript(enhancementScript) { _, error in
            if let error = error { print("Enhancement script failed: \(error)") }
        }
    }
    
    @objc private func processEdgeSwipe(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        guard recognizer.state == .ended,
              let swipedView = recognizer.view as? WKWebView else { return }
        
        if swipedView.canGoBack {
            swipedView.goBack()
        } else if gravitySupervisor.additionalGravityViews.last === swipedView {
            gravitySupervisor.revertGravity(to: nil)
        }
    }
    
    private func storeGravity(from webView: WKWebView) {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            var gravityDict: [String: [String: [HTTPCookiePropertyKey: Any]]] = [:]
            
            for cookie in cookies {
                var domainDict = gravityDict[cookie.domain] ?? [:]
                if let properties = cookie.properties {
                    domainDict[cookie.name] = properties
                }
                gravityDict[cookie.domain] = domainDict
            }
            
            UserDefaults.standard.set(gravityDict, forKey: "preserved_grains")
        }
    }
    
    func webView(_ webView: WKWebView,
                 runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    func webView(_ webView: WKWebView,
                 didFailProvisionalNavigation navigation: WKNavigation!,
                 withError error: Error) {
        if (error as NSError).code == NSURLErrorHTTPTooManyRedirects,
           let safeURL = lastKnownURL {
            webView.load(URLRequest(url: safeURL))
        }
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        redirectCount += 1
        
        if redirectCount > maxRedirectsPerMinute {
            webView.stopLoading()
            if let safeURL = lastKnownURL {
                webView.load(URLRequest(url: safeURL))
            }
            return
        }
        
        lastKnownURL = webView.url
        storeGravity(from: webView)
    }
    
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        
        lastKnownURL = url
        
        let schemeLower = (url.scheme ?? "").lowercased()
        let urlStringLower = url.absoluteString.lowercased()
        
        let internalSchemes: Set<String> = ["http", "https", "about", "blob", "data", "javascript", "file"]
        let internalPrefixes = ["srcdoc", "about:blank", "about:srcdoc"]
        
        let isInternal = internalSchemes.contains(schemeLower) ||
        internalPrefixes.contains { urlStringLower.hasPrefix($0) } ||
        urlStringLower == "about:blank"
        
        if isInternal {
            decisionHandler(.allow)
            return
        }
        
        UIApplication.shared.open(url, options: [:]) { _ in }
        
        decisionHandler(.cancel)
    }
    
    private func attachGravityConstraints(_ webView: WKWebView) {
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: gravitySupervisor.primaryGravityView.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: gravitySupervisor.primaryGravityView.trailingAnchor),
            webView.topAnchor.constraint(equalTo: gravitySupervisor.primaryGravityView.topAnchor),
            webView.bottomAnchor.constraint(equalTo: gravitySupervisor.primaryGravityView.bottomAnchor)
        ])
    }
}
