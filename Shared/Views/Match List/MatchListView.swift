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
	@Environment(\.shouldAnonymize) private var shouldAnonymize
	@Environment(\.location) private var location
	@EnvironmentObject private var bookmarkList: BookmarkList
	
	private var shownMatches: [CompetitiveUpdate] {
		matchList?.matches ?? []
	}
	
	var body: some View {
		List {
			Section(header: Text("Player", comment: "Match List: section")) {
				PlayerIdentityCell(user: user, identity: identity)
				
				CompetitiveSummaryCell(summary: summary)
				
				TransparentNavigationLink {
					if let user, let matchList {
						StatisticsContainer(user: user, matchList: matchList)
					}
				} label: {
					Label(
						String(localized: "View Stats", comment: "Match List"),
						systemImage: "chart.line.uptrend.xyaxis"
					)
					.padding(.vertical, 8)
				}
				.disabled(user == nil || matchList == nil)
			}
			
			Section(header: Text("Matches", comment: "Match List: section")) {
				ForEach(shownMatches) { match in
					MatchCell(match: match, userID: userID, filter: filter)
				}
				
				if matchList?.canLoadOlderMatches == true {
					AsyncButton {
						await updateMatchList(update: ValorantClient.loadOlderMatches)
					} label: {
						Label(
							String(localized: "Load Older Matches", comment: "Match List"),
							systemImage: "ellipsis"
						)
					}
				}
			}
		}
		.toolbar {
			ToolbarItemGroup(placement: .navigationBarTrailing) {
				if !shouldAnonymize(userID) {
					Button {
						bookmarkList.toggleBookmark(for: userID, location: location!)
					} label: {
						if bookmarkList.hasBookmark(for: userID) {
							Label(
								String(localized: "Remove Bookmark", comment: "Match List: accessibility label"),
								systemImage: "bookmark.fill"
							)
						} else {
							Label(
								String(localized: "Add Bookmark", comment: "Match List: accessibility label"),
								systemImage: "bookmark"
							)
						}
					}
				}
				
				Button {
					isEditingFilter = true
				} label: {
					Label(
						String(localized: "Edit Filter", comment: "Match List: accessibility label"),
						systemImage: "line.horizontal.3.decrease.circle"
					)
					.symbolVariant(filter.isActive ? .fill : .none)
				}
			}
		}
		.refreshable { await refresh() }
		.sheet(isPresented: $isEditingFilter) {
			MatchListFilterEditor(filter: $filter)
		}
		.withLocalData($user, id: userID, shouldAutoUpdate: true)
		.withLocalData($matchList, id: userID, shouldAutoUpdate: true)
		.withLocalData($summary, id: userID, shouldAutoUpdate: true)
		.withLocalData($identity, id: userID)
		.anonymizing(additionally: shouldAnonymize(userID) ? .all : .none)
		.navigationTitle(title)
	}
	
	var title: Text {
		if !shouldAnonymize(userID), let user {
			return Text(user.gameName)
		} else {
			return Text("Matches", comment: "Match List: title if name unknown/hidden")
		}
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

extension MatchListView {
	init(userID: User.ID) {
		self.init(
			userID: userID,
			user: .init(id: userID),
			matchList: .init(id: userID),
			summary: .init(id: userID),
			identity: .init(id: userID)
		)
	}
}

extension MatchListFilter: DefaultsValueConvertible {}

#if DEBUG
struct MatchListView_Previews: PreviewProvider {
	static var previews: some View {
		MatchListView(
			userID: PreviewData.userID,
			user: .init(preview: PreviewData.user),
			matchList: .init(preview: PreviewData.matchList),
			summary: .init(preview: PreviewData.summary),
			identity: .init(preview: PreviewData.userIdentity)
		)
		.withToolbar()
		.environmentObject(BookmarkList())
	}
}
#endif
