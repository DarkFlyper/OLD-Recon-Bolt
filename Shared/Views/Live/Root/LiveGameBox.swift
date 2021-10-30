import SwiftUI
import ValorantAPI
import HandyOperators

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
				Text("Currently \(activeMatch.inPregame ? "in agent select" : "in-game").")
				
				Group {
					if activeMatch.inPregame {
						NavigationLink {
							LiveGameContainer(userID: userID, activeMatch: activeMatch)
						} label: {
							HStack {
								Image(systemName: "person.fill.viewfinder")
								Text("Agent Select")
							}
						}
					} else {
						NavigationLink {
							LiveGameContainer(userID: userID, activeMatch: activeMatch)
						} label: {
							HStack {
								Image(systemName: "list.bullet.below.rectangle")
								Text("Match Details")
							}
						}
					}
				}
				.font(.headline)
				.imageScale(.large)
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
}

#if DEBUG
struct LiveGameBox_Previews: PreviewProvider {
    static var previews: some View {
		Group {
			LiveGameBox(userID: PreviewData.userID, refreshAction: {}, isAutoRefreshing: true)
				.inEachColorScheme()
			
			VStack(spacing: 16) {
				LiveGameBox(userID: PreviewData.userID, activeMatch: .init(id: Match.ID(), inPregame: true)) {}
				LiveGameBox(userID: PreviewData.userID, activeMatch: .init(id: Match.ID(), inPregame: false)) {}
				Spacer()
			}
			.withToolbar()
			.inEachColorScheme()
		}
		.padding()
		.background(Color(.systemGroupedBackground))
		.previewLayout(.sizeThatFits)
    }
}
#endif
