import SwiftUI
import ValorantAPI
import UserDefault

struct BookmarkListView: View {
	let userID: User.ID
	@State var myself: User?
	@State var isShowingSelf = true // initially show self
	
	@EnvironmentObject private var bookmarkList: BookmarkList
	
	var body: some View {
		List {
			Section {
				UserCell(userID: userID, isSelected: $isShowingSelf, user: myself)
			}
			.withLocalData($myself) { $0.user(for: userID) }
			
			Section("Bookmarks") {
				ForEach(bookmarkList.bookmarks, id: \.self) {
					OtherUserCell(userID: $0)
				}
			}
			.valorantLoadTask(id: bookmarkList.bookmarks) {
				try await LocalDataProvider.shared.fetchUsers(for: bookmarkList.bookmarks, using: $0)
			}
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
	
	struct UserCell: View {
		let userID: User.ID
		@Binding var isSelected: Bool
		@State var user: User?
		@State var identity: Player.Identity?
		
		var body: some View {
			NavigationLink(isActive: $isSelected) {
				MatchListView(userID: userID, user: user)
			} label: {
				HStack(spacing: 10) {
					if let identity = identity {
						PlayerCardImage.smallArt(identity.cardID)
							.frame(width: 64)
							.mask(RoundedRectangle(cornerRadius: 8, style: .continuous))
					}
					
					VStack(alignment: .leading) {
						if let user = user {
							HStack(spacing: 4) {
								Text(user.gameName)
									.fontWeight(.semibold)
								
								Text("#\(user.tagLine)")
									.foregroundStyle(.secondary)
							}
						} else {
							Text("Bookmarked Player")
						}
						
						if let identity = identity {
							Text("Level \(identity.accountLevel)")
						}
					}
					
					Spacer()
				}
			}
			.padding(.vertical, 8)
			.withLocalData($user) { $0.user(for: userID) }
			.withLocalData($identity) { $0.identity(for: userID) }
		}
	}
}

final class BookmarkList: ObservableObject {
	@UserDefault("BookmarkList.stored") private static var stored: [User.ID] = []
	
	@Published var bookmarks: [User.ID] = BookmarkList.stored {
		didSet { Self.stored = bookmarks }
	}
	
	init() {}
	
	#if DEBUG
	init(bookmarks: [User.ID]) {
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

extension User.ID: DefaultsValueConvertible {
	public typealias DefaultsRepresentation = Data // use codable
}

#if DEBUG
struct BookmarksList_Previews: PreviewProvider {
	static var previews: some View {
		BookmarkListView.UserCell(
			userID: PreviewData.userID,
			isSelected: .constant(false),
			user: PreviewData.user,
			identity: PreviewData.userIdentity
		)
		.padding()
		.frame(minWidth: 400)
		.previewLayout(.sizeThatFits)
		
		BookmarkListView(
			userID: PreviewData.userID,
			myself: PreviewData.user,
			isShowingSelf: false
		)
		.withToolbar()
		.environmentObject(BookmarkList(
			bookmarks: PreviewData.singleMatch.players.prefix(5).map(\.id) + [User.ID()]
		))
	}
}
#endif
