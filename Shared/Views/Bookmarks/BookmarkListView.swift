import SwiftUI
import ValorantAPI

struct BookmarkListView: View {
	let userID: User.ID
	@Binding var selection: SelectedBookmark?
	
	@EnvironmentObject private var bookmarkList: BookmarkList
	@StateObject var history = LookupHistory()
	
	var body: some View {
		List {
			Section {
				UserCell(userID: userID, isSelected: $selection.equals(.ownUser))
			}
			
			Section("Bookmarks") {
				ForEach(bookmarkList.bookmarks, id: \.self) { entry in
					UserCell(userID: entry.user, isSelected: $selection.equals(.other(entry.user)))
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
					UserCell(userID: entry.user, isSelected: $selection.equals(.other(entry.user)))
						.environment(\.location, entry.location)
				}
				.onDelete { history.entries.remove(atOffsets: $0) }
			}
			.headerProminence(.increased)
		}
		.navigationTitle("Players")
	}
}

enum SelectedBookmark: Hashable {
	case ownUser
	case other(User.ID)
	
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
			selection: .constant(nil),
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
