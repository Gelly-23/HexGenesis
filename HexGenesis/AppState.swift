import Foundation
import Combine

final class AppState: ObservableObject {
    private enum Keys {
        static let hasSeenOnboarding = "hasSeenOnboarding"
        static let isLoggedIn = "isLoggedIn"
    }

    @Published var hasSeenOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasSeenOnboarding, forKey: Keys.hasSeenOnboarding) }
    }

    @Published var isLoggedIn: Bool {
        didSet { UserDefaults.standard.set(isLoggedIn, forKey: Keys.isLoggedIn) }
    }

    init() {
        self.hasSeenOnboarding = false
        self.isLoggedIn = UserDefaults.standard.bool(forKey: Keys.isLoggedIn)
    }
    
    func logout() {
        isLoggedIn = false
    }

    func resetAllForDebug() {
        hasSeenOnboarding = false
        isLoggedIn = false
    }
}
