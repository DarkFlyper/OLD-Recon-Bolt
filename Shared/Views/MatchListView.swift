import SwiftUI
import Combine
import UserDefault
import ValorantAPI

struct MatchListView: View {
	@Binding var matchList: MatchList {
		didSet { matchList.save() }
	}
	@State @UserDefault("shouldShowUnranked") private var shouldShowUnranked = true
	@EnvironmentObject private var loadManager: LoadManager
	
	private var shownMatches: [CompetitiveUpdate] {
		shouldShowUnranked
			? matchList.matches
			: matchList.matches.filter(\.isRanked)
	}
	
	var body: some View {
		List {
			loadButton(
				title: matchList.estimatedMissedMatches > 0
					? "Load \(matchList.estimatedMissedMatches)+ Newer Matches"
					: "Load Newer Matches",
				task: ValorantClient.loadNewerMatches
			)
			
			ForEach(shownMatches, id: \.id, content: MatchCell.init)
			
			loadButton(
				title: "Load Older Matches",
				task: ValorantClient.loadOlderMatches
			)
		}
		.listStyle(PrettyListStyle())
		.toolbar {
			ToolbarItemGroup(placement: .leading) {
				Button(shouldShowUnranked ? "Hide Unranked" : "Show Unranked")
					{ shouldShowUnranked.toggle() }
			}
		}
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
}
