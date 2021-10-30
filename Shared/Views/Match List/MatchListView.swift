import SwiftUI
import ValorantAPI
import HandyOperators

struct MatchListView: View {
	let userID: User.ID
	
	@State var user: User?
	@State var matchList: MatchList?
	@State var summary: CareerSummary?
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
				if let user = user, let identity = identity {
					PlayerIdentityCell(user: user, identity: identity)
				}
				
				if let summary = summary {
					CompetitiveSummaryCell(summary: summary)
				}
			}
			
			Section(header: Text("Matches")) {
				ForEach(shownMatches) {
					MatchCell(match: $0, userID: userID)
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
					bookmarkList.toggleBookmark(for: userID)
				} label: {
					if bookmarkList.bookmarks.contains(userID) {
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
			}
		}
		.withLocalData($user, id: userID, shouldAutoUpdate: true)
		.withLocalData($matchList, id: userID, shouldAutoUpdate: true)
		.withLocalData($summary, id: userID, shouldAutoUpdate: true)
		.withLocalData($identity, id: userID)
		.refreshable { await refresh() }
		.onSceneActivation(perform: refresh)
		.loadErrorAlertTitle("Could not load matches!")
		.navigationTitle(user?.name ?? "Matches")
	}
	
	func refresh() async {
		async let matchListUpdate: Void = updateMatchList(update: ValorantClient.loadMatches)
		async let summaryUpdate: Void = load {
			try await $0.fetchCareerSummary(for: userID, forceFetch: true)
		}
		_ = await (matchListUpdate, summaryUpdate)
	}
	
	func updateMatchList(update: @escaping (ValorantClient) -> (inout MatchList) async throws -> Void) async {
		await load { try await $0.updateMatchList(for: userID, update: update($0)) }
	}
}

#if DEBUG
struct MatchListView_Previews: PreviewProvider {
	static var previews: some View {
		MatchListView(
			userID: PreviewData.userID,
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
