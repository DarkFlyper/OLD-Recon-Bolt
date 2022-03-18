import SwiftUI
import ValorantAPI
import HandyOperators

struct LiveGameBox: View {
	var userID: User.ID
	@State var party: Party?
	@State var activeMatch: ActiveMatch?
	@State var shownMatch: ActiveMatch?
	
	@AppStorage("LiveGameBox.shouldAutoRefresh")
	var shouldAutoRefresh = false
	@AppStorage("LiveGameBox.shouldAutoShow")
	var shouldAutoShow = false
	
	@Environment(\.valorantLoad) private var load
	
	var isInMatchmaking: Bool {
		party?.state == .inMatchmaking
	}
	
	var isAutoRefreshing: Bool {
		shouldAutoRefresh || isInMatchmaking
	}
	
	var body: some View {
		RefreshableBox(title: "Party", refreshAction: refresh) {
			Divider()
			
			VStack(spacing: 16) {
				content
			}
			.padding(16)
		}
		.onChange(of: activeMatch) { [activeMatch] newMatch in
			guard shouldAutoRefresh, shouldAutoShow, activeMatch?.id != newMatch?.id else { return }
			shownMatch = newMatch
		}
		.task(refresh)
		.onSceneActivation(perform: refresh)
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
		} else if let party = Binding($party) {
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
						await refresh()
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
		.animation(.default, value: isAutoRefreshing)
	}
	
	@Sendable
	func refresh() async {
		// load independently & concurrently
		// TODO: change once `async let _ = ...` is fixed
		async let activeMatchUpdate: Void = loadActiveMatch()
		async let partyUpdate: Void = loadParty()
		_ = await (activeMatchUpdate, partyUpdate)
	}
	
	func loadActiveMatch() async {
		await load {
			activeMatch = try await $0.getActiveMatch()
		}
	}
	
	func loadParty() async {
		await load {
			party = try await $0.getPartyInfo()
			if let party = party {
				LocalDataProvider.dataFetched(party)
				try await $0.fetchUsers(for: party.members.map(\.id))
			}
		}
	}
}

#if DEBUG
struct LiveGameBox_Previews: PreviewProvider {
	static var previews: some View {
		Group {
			LiveGameBox(
				userID: PreviewData.userID,
				shouldAutoRefresh: true
			)
			LiveGameBox(
				userID: PreviewData.userID,
				party: PreviewData.party
			)
		}
		.padding()
		.background(Color.groupedBackground)
		.previewLayout(.sizeThatFits)
		.inEachColorScheme()
		
		VStack(spacing: 16) {
			LiveGameBox(
				userID: PreviewData.userID,
				activeMatch: .init(id: Match.ID(), inPregame: true)
			)
			LiveGameBox(
				userID: PreviewData.userID,
				activeMatch: .init(id: Match.ID(), inPregame: false)
			)
			Spacer()
		}
		.padding()
		.background(Color.groupedBackground)
		.withToolbar()
		.inEachColorScheme()
	}
}
#endif
