import SwiftUI
import ValorantAPI

struct BookmarkListView: View {
	let userID: User.ID
	@State var selection: SelectedBookmark? = .ownUser
	
	@EnvironmentObject private var bookmarkList: BookmarkList
	@StateObject var history = LookupHistory()
	
	var body: some View {
		ScrollViewReader { scrollView in
			List {
				content()
			}
			.deepLinkHandler { link in
				guard
					case .widget(let link) = link,
					case .career(let id) = link.destination
				else { return }
				
				selection = .init(userID: id)
				scrollView.scrollTo(selection)
			}
		}
		.navigationTitle("Players")
	}
	
	@ViewBuilder
	func content() -> some View {
		Section {
			userCell(id: nil)
		}
		
		Section("Bookmarks") {
			ForEach(bookmarkList.bookmarks, id: \.self) { entry in
				userCell(id: entry.user)
					.environment(\.location, entry.location)
			}
			.onDelete { bookmarkList.bookmarks.remove(atOffsets: $0) }
			.onMove { bookmarkList.bookmarks.move(fromOffsets: $0, toOffset: $1) }
		}
		.headerProminence(.increased)
		.valorantLoadTask(id: bookmarkList.bookmarks) {
			try await $0.fetchUsers(for: bookmarkList.bookmarks.map(\.id))
		}
		
		Section("Search") {
			LookupCell(history: history)
			
			ForEach(history.entries) { entry in
				if !bookmarkList.hasBookmark(for: entry.user) {
					userCell(id: entry.user)
						.environment(\.location, entry.location)
				}
			}
			.onDelete { history.entries.remove(atOffsets: $0) }
		}
		.headerProminence(.increased)
	}
	
	@ViewBuilder
	func userCell(id: User.ID?) -> some View {
		let tag = SelectedBookmark(userID: id)
		UserCell(userID: id ?? userID, isSelected: $selection.equals(tag))
			.id(tag)
	}
}

enum SelectedBookmark: Hashable {
	case ownUser
	case other(User.ID)
	
	init(userID: User.ID?) {
		self = userID.map(Self.other) ?? .ownUser
	}
	
	var userID: User.ID? {
		switch self {
		case .ownUser:
			return nil
		case .other(let user):
			return user
		}
	}
}

#if DEBUG
struct BookmarksList_Previews: PreviewProvider {
	static var previews: some View {
		BookmarkListView(
			userID: PreviewData.userID,
			history: LookupHistory(
				entries: PreviewData.liveGameInfo.players.prefix(3)
					.map { .init(user: $0.id, location: .europe) }
			)
		)
		.withToolbar(allowLargeTitles: false)
		.environmentObject(BookmarkList(
			bookmarks: (PreviewData.pregameInfo.team.players.map(\.id) + [.init()])
				.map { .init(user: $0, location: .europe) }
		))
	}
}
#endif
