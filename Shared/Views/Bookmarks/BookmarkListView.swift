import SwiftUI
import ValorantAPI

struct BookmarkListView: View {
	let userID: User.ID
	@LocalData var myself: User?
	@State var isShowingSelf = true // initially show self
	
	@EnvironmentObject private var bookmarkList: BookmarkList
	@StateObject var history = LookupHistory()
	
	var body: some View {
		List {
			Section {
				UserCell(userID: userID, isSelected: $isShowingSelf, user: myself)
			}
			.withLocalData($myself, id: userID, shouldAutoUpdate: true)
			
			Section("Bookmarks") {
				ForEach(bookmarkList.bookmarks, id: \.self) { entry in
					OtherUserCell(userID: entry.user)
						.environment(\.location, entry.location)
				}
			}
			.headerProminence(.increased)
			.valorantLoadTask(id: bookmarkList.bookmarks) {
				try await $0.fetchUsers(for: bookmarkList.bookmarks.map(\.id))
			}
			
			Section("Search") {
				LookupCell(history: history)
				
				ForEach(history.entries) { entry in
					OtherUserCell(userID: entry.user)
						.environment(\.location, entry.location)
				}
			}
			.headerProminence(.increased)
		}
		.navigationTitle("Players")
	}
	
	struct OtherUserCell: View {
		let userID: User.ID
		@State var isSelected = false
		
		var body: some View {
			UserCell(userID: userID, isSelected: $isSelected)
		}
	}
}

#if DEBUG
struct BookmarksList_Previews: PreviewProvider {
	static var previews: some View {
		BookmarkListView(
			userID: PreviewData.userID,
			myself: PreviewData.user,
			isShowingSelf: false,
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
