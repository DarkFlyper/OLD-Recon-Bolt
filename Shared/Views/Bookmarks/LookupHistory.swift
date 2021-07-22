import Combine
import ValorantAPI
import UserDefault

@MainActor
final class LookupHistory: ObservableObject {
	@UserDefault("LookupHistory.stored")
	private static var stored: [User.ID] = []
	private static let maxCount = 5
	
	@Published var entries: [User.ID] = LookupHistory.stored {
		didSet { Self.stored = entries }
	}
	
	init() {}
	
#if DEBUG
	init(entries: [User.ID]) {
		assert(isInSwiftUIPreview)
		_entries = .init(wrappedValue: entries)
	}
#endif
	
	func lookedUp(_ user: User.ID) {
		entries = [user] + entries
			.filter { $0 != user }
			.prefix(Self.maxCount - 1)
	}
}
