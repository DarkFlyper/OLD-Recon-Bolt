import SwiftUI
import Combine
import UserDefault
import ValorantAPI

struct MatchListView: View {
	@Binding var matchList: MatchList
	@State @UserDefault("shouldShowUnranked") private var shouldShowUnranked = true
	@EnvironmentObject private var loadManager: ValorantLoadManager
	@EnvironmentObject private var dataStore: ClientDataStore
	
	private var shownMatches: [CompetitiveUpdate] {
		shouldShowUnranked
			? matchList.matches
			: matchList.matches.filter(\.isRanked)
	}
	
	var body: some View {
		List {
			loadManager.loadButton("Load Matches") {
				$0.load { $0.loadMatches(for: matchList) }
					onSuccess: { matchList = $0 }
			}
			.frame(maxWidth: .infinity, alignment: .center)
			
			ForEach(shownMatches, id: \.id, content: MatchCell.init)
		}
		.listStyle(PrettyListStyle())
		.toolbar {
			Button(shouldShowUnranked ? "Hide Unranked" : "Show Unranked")
				{ shouldShowUnranked.toggle() }
		}
		.onChange(of: dataStore.data?.id) { _ in
			loadMatches()
		}
		.loadErrorTitle("Could not load matches!")
		.navigationTitle(matchList.user.account.name)
	}
	
	private func loadButton(
		title: String,
		task: @escaping (ValorantClient) -> (MatchList) -> AnyPublisher<MatchList, Error>
	) -> some View {
		loadManager.loadButton(title) {
			$0.load { task($0)(matchList) }
				onSuccess: { matchList = $0 }
		}
		.frame(maxWidth: .infinity, alignment: .center)
	}
	
	func loadMatches() {
		if matchList.matches.isEmpty {
			loadManager
				.load { $0.loadMatches(for: matchList) }
					onSuccess: { matchList = $0 }
		}
	}
}

#if DEBUG
struct MatchListView_Previews: PreviewProvider {
	static var previews: some View {
		MatchListView(matchList: .constant(PreviewData.matchList))
			.withToolbar()
			.withMockData()
			.inEachColorScheme()
	}
}
#endif
