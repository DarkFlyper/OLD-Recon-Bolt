import SwiftUI

final class AppSettings: ObservableObject {
	@AppStorage("AppSettings.theme")
	var theme = Theme.system
	
	@AppStorage("vibrateOnMatchFound")
	var vibrateOnMatchFound = true
	
	enum Theme: String, Hashable, Codable, CaseIterable {
		case system
		case light
		case dark
	}
}

extension AppSettings.Theme {
	var colorScheme: ColorScheme? {
		switch self {
		case .system:
			return nil
		case .light:
			return .light
		case .dark:
			return .dark
		}
	}
}
