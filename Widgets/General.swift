import SwiftUI
import Intents

enum FakeError: Error {
	case blankPreview
	
	var errorDescription: String? { "" }
}

extension AccentColor {
	var color: Color {
		switch self {
		case .unknown:
			fallthrough
		case .red:
			return .valorantRed
		case .blue:
			return .valorantBlue
		case .highlight:
			return .valorantSelf
		case .primary:
			return .primary
		}
	}
}
