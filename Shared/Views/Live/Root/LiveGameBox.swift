import SwiftUI
import ValorantAPI

struct LiveGameBox: View {
	var userID: User.ID
	var activeMatch: ActiveMatch?
	var refreshAction: () async -> Void
	
	@State var isAutoRefreshing = false
	
	var body: some View {
		RefreshableBox(title: "Live Game", refreshAction: refreshAction) {
			Divider()
			
			content
				.padding(16)
		}
	}
	
	@ViewBuilder
	private var content: some View {
		if let activeMatch = activeMatch {
			GroupBox {
				Text("Currently \(activeMatch.inPregame ? "in agent select" : "in-game")!")
				
				if activeMatch.inPregame {
					NavigationLink("Agent Select \(Image(systemName: "chevron.right"))") {
						AgentSelectContainer(matchID: activeMatch.id, userID: userID)
					}
				} else {
					NavigationLink("Match Details \(Image(systemName: "chevron.right"))") {
						LiveMatchContainer(matchID: activeMatch.id, userID: userID)
					}
				}
			}
		} else {
			VStack(spacing: 16) {
				GroupBox {
					Text("Not currently in a match!")
						.foregroundColor(.secondary)
				}
				
				HStack(spacing: 10) {
					if isAutoRefreshing {
						AutoRefresher(refreshAction: refreshAction)
					}
					
					Toggle("Auto-Refresh", isOn: $isAutoRefreshing)
				}
			}
		}
	}
	
	struct ActiveMatch {
		var id: Match.ID
		var inPregame: Bool
	}
}

#if DEBUG
struct LiveGameBox_Previews: PreviewProvider {
    static var previews: some View {
		Group {
			LiveGameBox(userID: PreviewData.userID, refreshAction: {}, isAutoRefreshing: true)
				.inEachColorScheme()
			LiveGameBox(userID: PreviewData.userID, activeMatch: .init(id: Match.ID(), inPregame: true)) {}
				.preferredColorScheme(.light)
			LiveGameBox(userID: PreviewData.userID, activeMatch: .init(id: Match.ID(), inPregame: false)) {}
				.preferredColorScheme(.dark)
		}
		.padding()
		.background(Color(.systemGroupedBackground))
		.previewLayout(.sizeThatFits)
    }
}
#endif
