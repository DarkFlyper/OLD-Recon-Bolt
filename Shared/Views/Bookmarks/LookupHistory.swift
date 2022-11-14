import Combine
import ValorantAPI
import UserDefault

@MainActor
final class LookupHistory: ObservableObject {
	@UserDefault("LookupHistory.stored")
	private static var stored: [Entry] = []
	private static let maxCount = 3
	
	@Published var entries: [Entry] = LookupHistory.stored {
		didSet { Self.stored = entries }
	}
	
	init() {}
	
#if DEBUG
	init(entries: [Entry]) {
		assert(isInSwiftUIPreview)
		_entries = .init(wrappedValue: entries)
	}
#endif
	
	func lookedUp(_ user: User.ID, location: Location) {
		let entry = Entry(user: user, location: location)
		entries = [entry] + entries
			.filter { $0.user != user }
			.prefix(Self.maxCount - 1)
	}
	
	struct Entry: Hashable, Identifiable, Codable, DefaultsValueConvertible {
		let user: User.ID
		let location: Location
		
		var id: User.ID { user }
	}
}
