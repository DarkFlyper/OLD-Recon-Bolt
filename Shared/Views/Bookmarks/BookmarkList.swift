import Foundation
import Combine
import ValorantAPI
import UserDefault

@MainActor
final class BookmarkList: ObservableObject {
	@UserDefault("BookmarkList.stored.v2", migratingTo: .shared)
	private var stored: [Entry] = []
	
	@Published var bookmarks: [Entry] {
		didSet { stored = bookmarks }
	}
	
	init() {
		self.bookmarks = _stored.wrappedValue
		if bookmarks.isEmpty, BackwardsCompatibility.canMigrate {
			Task {
				guard let location = AccountManager().activeAccount?.location else { return }
				bookmarks = BackwardsCompatibility.migrate(location: location)
			}
		}
	}
	
#if DEBUG
	init(bookmarks: [Entry]) {
		assert(isInSwiftUIPreview)
		self.bookmarks = bookmarks
	}
#endif
	
	func addBookmark(for user: User.ID, location: Location) {
		if !hasBookmark(for: user) {
			bookmarks.append(.init(user: user, location: location))
		}
	}
	
	func removeBookmark(for user: User.ID) {
		bookmarks.removeAll { $0.user == user }
	}
	
	func hasBookmark(for user: User.ID) -> Bool {
		bookmarks.contains(where: { $0.user == user })
	}
	
	func toggleBookmark(for user: User.ID, location: Location) {
		if hasBookmark(for: user) {
			removeBookmark(for: user)
		} else {
			addBookmark(for: user, location: location)
		}
	}
	
	struct Entry: Hashable, Identifiable, Codable, DefaultsValueConvertible {
		let user: User.ID
		let location: Location
		
		var id: User.ID { user }
	}
	
	enum BackwardsCompatibility {
		@UserDefault("BookmarkList.stored")
		private static var stored: [User.ID] = []
		
		static var canMigrate: Bool {
			!stored.isEmpty
		}
		
		static func migrate(location: Location) -> [Entry] {
			let migrated = stored.map { Entry(user: $0, location: location) }
			stored = []
			return migrated
		}
	}
}
