import SwiftUI

@MainActor
@Observable
final class AppSettings {
    static let shared = AppSettings()

    var theme: AppTheme {
        didSet { persist(theme.rawValue, forKey: AppStorageKey.theme) }
    }

    var showProgress: Bool {
        didSet { persist(showProgress, forKey: AppStorageKey.showProgress) }
    }

    var progressPosition: ProgressBarPosition {
        didSet { persist(progressPosition.rawValue, forKey: AppStorageKey.progressPosition) }
    }

    private init() {
        let defaults = UserDefaults.standard
        theme = AppTheme(rawValue: defaults.string(forKey: AppStorageKey.theme) ?? "") ?? .system
        showProgress = defaults.bool(forKey: AppStorageKey.showProgress)
        progressPosition = ProgressBarPosition(
            rawValue: defaults.string(forKey: AppStorageKey.progressPosition) ?? ""
        ) ?? .top
    }

    private func persist(_ value: Any, forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
}
