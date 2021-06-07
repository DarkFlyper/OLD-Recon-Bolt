import SwiftUI
import Combine
import ValorantAPI

struct UserView: View {
	@State private var matchList: MatchList
	@EnvironmentObject private var loadManager: ValorantLoadManager
	
	init(for user: User) {
		_matchList = .init(wrappedValue: .init(user: user))
	}
	
	var body: some View {
		MatchListView(matchList: $matchList)
			.navigationBarTitleDisplayMode(.large)
	}
}

struct MatchListView: View {
	@Binding var matchList: MatchList
	@AppStorage("MatchListView.shouldShowUnranked") private var shouldShowUnranked = true
	@EnvironmentObject private var loadManager: ValorantLoadManager
	
	private var shownMatches: [CompetitiveUpdate] {
		shouldShowUnranked
			? matchList.matches
			: matchList.matches.filter(\.isRanked)
	}
	
	var body: some View {
		List {
			Button(action: loadMatches) {
				Label("Load Matches", systemImage: "arrow.clockwise")
			}
			.disabled(!loadManager.canLoad)
			.buttonStyle(UnifiedLinkButtonStyle())
			.padding(10)
			.frame(maxWidth: .infinity, alignment: .center)
			
			ForEach(shownMatches, id: \.id) {
				MatchCell(match: $0, userID: matchList.user.id)
			}
		}
		.toolbar {
			Button(shouldShowUnranked ? "Hide Unranked" : "Show Unranked")
				{ shouldShowUnranked.toggle() }
		}
		.onAppear {
			if matchList.matches.isEmpty {
				loadMatches()
			}
		}
		.loadErrorTitle("Could not load matches!")
		.navigationTitle(matchList.user.name)
	}
	
	func loadMatches() {
		loadManager.load { $0.loadMatches(for: matchList) }
			onSuccess: { new in withAnimation { matchList = new } }
	}
}

#if DEBUG
struct MatchListView_Previews: PreviewProvider {
	static var previews: some View {
		MatchListView(matchList: .constant(PreviewData.matchList))
			.withToolbar()
			.inEachColorScheme()
			.withMockValorantLoadManager()
			.withPreviewAssets()
	}
}
#endif
