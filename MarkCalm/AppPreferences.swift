import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable, Hashable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

enum ProgressBarPosition: String, CaseIterable, Identifiable, Hashable {
    case top
    case bottom

    var id: String { rawValue }

    var label: String {
        switch self {
        case .top: "Top"
        case .bottom: "Bottom"
        }
    }
}

enum AppStorageKey {
    static let theme = "theme"
    static let showProgress = "showProgress"
    static let progressPosition = "progressPosition"
    static let hasDismissedDefaultAppPrompt = "hasDismissedDefaultAppPrompt"
}
