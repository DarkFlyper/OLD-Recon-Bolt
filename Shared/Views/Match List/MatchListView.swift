import SwiftUI
import ValorantAPI
import HandyOperators
import UserDefault

struct MatchListView: View {
	let userID: User.ID
	
	@LocalData var user: User?
	@LocalData var matchList: MatchList?
	@LocalData var summary: CareerSummary?
	@LocalData var identity: Player.Identity?
	@State var isEditingFilter = false
	@UserDefault.State("MatchListView.filter") var filter = MatchListFilter()
	
	@Environment(\.valorantLoad) private var load
	@EnvironmentObject private var bookmarkList: BookmarkList
	
	private var shownMatches: [CompetitiveUpdate] {
		matchList?.matches ?? []
	}
	
	var body: some View {
		List {
			Section(header: Text("Player")) {
				if let user, let identity {
					PlayerIdentityCell(user: user, identity: identity)
				}
				
				if let summary {
					CompetitiveSummaryCell(summary: summary)
				}
			}
			
			Section(header: Text("Matches")) {
				ForEach(shownMatches) { match in
					MatchCell(match: match, userID: userID, filter: filter)
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
					isEditingFilter = true
				} label: {
					Label("Edit Filter", systemImage: "line.horizontal.3.decrease.circle")
						.symbolVariant(filter.isActive ? .fill : .none)
				}
			}
		}
		.sheet(isPresented: $isEditingFilter) {
			MatchListFilterEditor(filter: $filter)
		}
		.withLocalData($user, id: userID, shouldAutoUpdate: true)
		.withLocalData($matchList, id: userID, shouldAutoUpdate: true)
		.withLocalData($summary, id: userID, shouldAutoUpdate: true)
		.withLocalData($identity, id: userID)
		.refreshable { await refresh() }
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

extension MatchListFilter: DefaultsValueConvertible {}

#if DEBUG
struct MatchListView_Previews: PreviewProvider {
	static var previews: some View {
		MatchListView(
			userID: PreviewData.userID,
			user: PreviewData.user,
			matchList: PreviewData.matchList,
			summary: PreviewData.summary,
			identity: PreviewData.userIdentity
		)
		.withToolbar()
		.environmentObject(BookmarkList())
	}
}
#endif
