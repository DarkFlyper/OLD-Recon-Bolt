import SwiftUI
import ValorantAPI
import UserDefault

struct BookmarkListView: View {
	let userID: User.ID
	@State var myself: User?
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
				ForEach(bookmarkList.bookmarks, id: \.self) {
					OtherUserCell(userID: $0)
				}
			}
			.headerProminence(.increased)
			.valorantLoadTask(id: bookmarkList.bookmarks) {
				try await $0.fetchUsers(for: bookmarkList.bookmarks)
			}
			
			Section("Search") {
				LookupCell(history: history)
				
				ForEach(history.entries, id: \.self) {
					OtherUserCell(userID: $0)
				}
			}
			.headerProminence(.increased)
		}
		.navigationTitle("Players")
	}
	
	struct LookupCell: View {
		@State var gameName = ""
		@State var tagLine = ""
		@State var isLoading = false
		@ObservedObject var history: LookupHistory
		
		@FocusState private var focusedField: Field?
		
		@Environment(\.loadWithErrorAlerts) private var load
		
		@ScaledMetric(relativeTo: .body) private var maxNameFieldWidth = 150
		@ScaledMetric(relativeTo: .body) private var tagFieldWidth = 50
		
		var body: some View {
			ZStack {
				// this button is not visible but triggers when the cell is tapped—.onTapGesture breaks actual buttons in the cell
				Button("cell tap trigger") {
					// FIXME: @FocusState seems to be broken in Lists :<
					print("cell tapped!")
					focusedField = .gameName
				}
				.opacity(0)
				
				content
			}
		}
		
		private var content: some View {
			ScrollViewReader { scrollView in
				HStack {
					TextField("Name", text: $gameName)
						.frame(maxWidth: maxNameFieldWidth)
						.focused($focusedField, equals: .gameName)
						.submitLabel(.next)
						.onSubmit {
							focusedField = .tagLine
						}
					
					HStack {
						Text("#")
							.foregroundStyle(.secondary)
						
						TextField("Tag", text: $tagLine)
							.frame(width: tagFieldWidth)
							.focused($focusedField, equals: .tagLine)
							.submitLabel(.search)
							.onSubmit { lookUpPlayer(scrollView: scrollView) }
					}
					.onTapGesture {
						focusedField = .tagLine
					}
					
					Spacer()
					
					Button {
						lookUpPlayer(scrollView: scrollView)
					} label: {
						Label("Look Up", systemImage: "magnifyingglass")
					}
					.disabled(gameName.isEmpty || tagLine.isEmpty)
					.fixedSize()
					.overlay {
						if isLoading {
							ProgressView()
						}
					}
				}
				.disabled(isLoading)
				.padding(.vertical, 8)
			}
		}
		
		private func lookUpPlayer(scrollView: ScrollViewProxy) {
			Task {
				isLoading = true
				await load {
					let user = try await HenrikClient.shared.lookUpPlayer(name: gameName, tag: tagLine)
					LocalDataProvider.dataFetched(user)
					dispatchPrecondition(condition: .onQueue(.main))
					history.lookedUp(user.id)
					scrollView.scrollTo(user.id, anchor: nil) // TODO: this doesn't seem to do anything
				}
				isLoading = false
			}
		}
		
		enum Field: Hashable {
			case gameName
			case tagLine
		}
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
							.frame(width: 64, height: 64)
							.mask(RoundedRectangle(cornerRadius: 4, style: .continuous))
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
							Text("Unknown Player")
						}
						
						if let identity = identity {
							Text("Level \(identity.accountLevel)")
						}
					}
					
					Spacer()
				}
			}
			.padding(.vertical, 8)
			.withLocalData($user, id: userID)
			.withLocalData($identity, id: userID)
		}
	}
}

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
		entries = [user] + entries.filter { $0 != user }
	}
}

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
			isShowingSelf: false,
			history: LookupHistory(entries: PreviewData.liveGameInfo.players.prefix(3).map(\.id))
		)
		.withToolbar(allowLargeTitles: false)
		.environmentObject(BookmarkList(
			bookmarks: PreviewData.pregameInfo.team.players.map(\.id) + [.init()]
		))
		.inEachColorScheme()
	}
}
#endif
