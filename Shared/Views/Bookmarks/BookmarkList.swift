import Combine
import ValorantAPI
import UserDefault

@MainActor
final class BookmarkList: ObservableObject {
	@UserDefault("BookmarkList.stored")
	private static var stored: [User.ID] = []
	
	@Published var bookmarks: [User.ID] = BookmarkList.stored {
		didSet { Self.stored = bookmarks }
	}
	
	init() {}
	
#if DEBUG
	init(bookmarks: [User.ID]) {
		assert(isInSwiftUIPreview)
		_bookmarks = .init(wrappedValue: bookmarks)
	}
#endif
	
	func addBookmark(for user: User.ID) {
		if !bookmarks.contains(user) {
			bookmarks.append(user)
		}
	}
	
	func removeBookmark(for user: User.ID) {
		bookmarks.removeAll { $0 == user }
	}
	
	func toggleBookmark(for user: User.ID) {
		if bookmarks.contains(user) {
			removeBookmark(for: user)
		} else {
			addBookmark(for: user)
		}
	}
}
