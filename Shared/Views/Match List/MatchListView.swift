import SwiftUI
import ValorantAPI
import HandyOperators

struct MatchListView: View {
	let user: User
	
	@State var matchList: MatchList?
	@State var summary: CompetitiveSummary?
	@State var identity: Player.Identity?
	@State var shouldShowUnranked = true
	
	@Environment(\.valorantLoad) private var load
	@EnvironmentObject private var bookmarkList: BookmarkList
	
	private var shownMatches: [CompetitiveUpdate] {
		let matches = matchList?.matches ?? []
		return shouldShowUnranked ? matches : matches.filter(\.isRanked)
	}
	
	var body: some View {
		List {
			Section(header: Text("Player")) {
				if let identity = identity {
					PlayerIdentityCell(user: user, identity: identity)
				}
				
				if let summary = summary {
					CompetitiveSummaryCell(summary: summary)
				}
			}
			
			Section(header: Text("Matches")) {
				ForEach(shownMatches) {
					MatchCell(match: $0, userID: user.id)
				}
				
				if matchList?.canLoadOlderMatches == true {
					AsyncButton {
						await updateMatchList(update: ValorantClient.loadOlderMatches)
					} label: {
						Label("Load Older Matches", systemImage: "ellipsis")
					}
				}
			}
		}
		.toolbar {
			ToolbarItemGroup(placement: .navigationBarTrailing) {
				Button {
					bookmarkList.toggleBookmark(for: user.id)
				} label: {
					if bookmarkList.bookmarks.contains(user.id) {
						Label("Remove Bookmark", systemImage: "bookmark.fill")
					} else {
						Label("Add Bookmark", systemImage: "bookmark")
					}
				}
				
				Button {
					withAnimation { shouldShowUnranked.toggle() }
				} label: {
					if shouldShowUnranked {
						Label("Hide Unranked", systemImage: "line.horizontal.3.decrease.circle")
					} else {
						Label("Show Unranked", systemImage: "line.horizontal.3.decrease.circle.fill")
					}
				}
				
				#if DEBUG
				Button {
					LocalDataProvider.shared.store(matchList! <- {
						$0.matches.removeFirst()
						$0.highestLoadedIndex = 0
					})
				} label: {
					Label("Remove First Match", systemImage: "minus.circle")
				}
				#endif
			}
		}
		.withLocalData($matchList) { $0.matchList(for: user.id) }
		.withLocalData($summary) { $0.competitiveSummary(for: user.id) }
		.withLocalData($identity) { $0.identity(for: user.id) }
		.valorantLoadTask {
			try await LocalDataProvider.shared
				.autoUpdateMatchList(for: user.id, using: $0)
		}
		.valorantLoadTask {
			try await LocalDataProvider.shared
				.fetchCompetitiveSummary(for: user.id, using: $0)
		}
		.refreshable {
			async let matchListUpdate: Void = updateMatchList(update: ValorantClient.loadMatches)
			async let summaryUpdate: Void = load {
				try await LocalDataProvider.shared
					.fetchCompetitiveSummary(for: user.id, using: $0)
			}
			_ = await (matchListUpdate, summaryUpdate)
		}
		.loadErrorAlertTitle("Could not load matches!")
		.navigationTitle(user.name)
	}
	
	func updateMatchList(update: @escaping (ValorantClient) -> (inout MatchList) async throws -> Void) async {
		guard let matchList = matchList else { return }
		await load { client in
			LocalDataProvider.shared
				.store(try await matchList <- update(client))
		}
	}
}

#if DEBUG
struct MatchListView_Previews: PreviewProvider {
	static var previews: some View {
		MatchListView(
			user: PreviewData.user,
			matchList: PreviewData.matchList,
			summary: PreviewData.summary,
			identity: PreviewData.userIdentity,
			shouldShowUnranked: true
		)
		.withToolbar()
		.inEachColorScheme()
		.environmentObject(BookmarkList())
	}
}
#endif
