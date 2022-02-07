import SwiftUI
import ValorantAPI
import HandyOperators

struct LiveGameBox: View {
	var userID: User.ID
	var party: Party?
	var activeMatch: ActiveMatch?
	var refreshAction: () async -> Void
	
	@AppStorage("LiveGameBox.shouldAutoRefresh")
	var shouldAutoRefresh = false
	@AppStorage("LiveGameBox.shouldAutoShow")
	var shouldAutoShow = false
	
	@State var shownMatch: ActiveMatch?
	
	var isInMatchmaking: Bool {
		party?.queueEntryTime != nil
	}
	
	var isAutoRefreshing: Bool {
		shouldAutoRefresh || isInMatchmaking
	}
	
	var body: some View {
		RefreshableBox(title: "Party", refreshAction: refreshAction) {
			Divider()
			
			VStack(spacing: 16) {
				content
			}
			.padding(16)
		}
		.onChange(of: activeMatch) { newMatch in
			guard shouldAutoRefresh, shouldAutoShow, activeMatch?.id != newMatch?.id else { return }
			shownMatch = newMatch
		}
	}
	
	@ViewBuilder
	private var content: some View {
		if let activeMatch = activeMatch {
			GroupBox {
				Text("Currently \(activeMatch.inPregame ? "in agent select" : "in-game").")
				
				Group {
					NavigationLink(tag: activeMatch, selection: $shownMatch) {
						LiveGameContainer(userID: userID, activeMatch: activeMatch)
					} label: {
						HStack {
							if activeMatch.inPregame {
								Image(systemName: "person.fill.viewfinder")
								Text("Agent Select")
							} else {
								Image(systemName: "list.bullet.below.rectangle")
								Text("Match Details")
							}
						}
					}
				}
				.font(.headline)
				.imageScale(.large)
			}
		} else if let party = party {
			PartyInfoBox(userID: userID, party: party)
		} else {
			GroupBox {
				Text("Game is not running!")
					.foregroundColor(.secondary)
			}
		}
		
		VStack(spacing: 16) {
			HStack(spacing: 10) {
				if isAutoRefreshing {
					AutoRefresher {
						await refreshAction()
					}
				}
				
				Toggle("Refresh automatically", isOn: .init(
					get: { isAutoRefreshing }, // force auto refresh while in matchmaking
					set: { shouldAutoRefresh = $0 }
				))
				.disabled(isInMatchmaking)
			}
			
			if isAutoRefreshing {
				Toggle("Show details when found", isOn: $shouldAutoShow)
			}
		}
	}
}

#if DEBUG
struct LiveGameBox_Previews: PreviewProvider {
    static var previews: some View {
		Group {
			LiveGameBox(userID: PreviewData.userID, refreshAction: {}, shouldAutoRefresh: true)
			LiveGameBox(userID: PreviewData.userID, party: PreviewData.party) {}
		}
		.padding()
		.background(Color(.systemGroupedBackground))
		.previewLayout(.sizeThatFits)
		.inEachColorScheme()
		
		VStack(spacing: 16) {
			LiveGameBox(userID: PreviewData.userID, activeMatch: .init(id: Match.ID(), inPregame: true)) {}
			LiveGameBox(userID: PreviewData.userID, activeMatch: .init(id: Match.ID(), inPregame: false)) {}
			Spacer()
		}
		.padding()
		.background(Color(.systemGroupedBackground))
		.withToolbar()
		.inEachColorScheme()
    }
}
#endif
