import SwiftUI
import ValorantAPI
import HandyOperators

// TODO: this seems overkill at this point
struct UserView: View {
	let user: User
	
	@State private var shouldShowUnranked = true
	
	init(for user: User) {
		self.user = user
	}
	
	var body: some View {
		MatchListView(user: user, shouldShowUnranked: $shouldShowUnranked)
			.navigationBarTitleDisplayMode(.large)
	}
}

extension MatchList: Equatable {
	static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.matches.map(\.id) == rhs.matches.map(\.id)
	}
}

struct MatchListView: View {
	let user: User
	
	@State var matchList: MatchList?
	@Binding var shouldShowUnranked: Bool
	
	@Environment(\.valorantLoad) private var load
	
	private var shownMatches: [CompetitiveUpdate] {
		let matches = matchList?.matches ?? []
		return shouldShowUnranked ? matches : matches.filter(\.isRanked)
	}
	
	var body: some View {
		List {
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
		.toolbar {
			ToolbarItemGroup(placement: .navigationBarTrailing) {
				Button {
					withAnimation { shouldShowUnranked.toggle() }
				} label: {
					Image(
						systemName: shouldShowUnranked
							? "line.horizontal.3.decrease.circle"
							: "line.horizontal.3.decrease.circle.fill"
					)
				}
				
				#if DEBUG
				Button {
					LocalDataProvider.shared.store(matchList! <- { $0.matches.removeFirst() })
				} label: {
					Image(systemName: "minus.circle")
				}
				#endif
			}
		}
		.withLocalData($matchList) { $0.matchList(for: user.id) }
		.valorantLoadTask {
			try await LocalDataProvider.shared
				.autoUpdateMatchList(for: user.id, using: $0)
		}
		.refreshable {
			await updateMatchList(update: ValorantClient.loadMatches)
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
		MatchListView(user: PreviewData.user, matchList: PreviewData.matchList, shouldShowUnranked: .constant(true))
			.withToolbar()
			.inEachColorScheme()
			.listStyle(.grouped)
	}
}
#endif
