import SwiftUI
import ValorantAPI
import HandyOperators
import AudioToolbox

struct LiveGameBox: View {
	var userID: User.ID
	@State var party: Party?
	@State var activeMatch: ActiveMatch?
	@State var shownMatch: ActiveMatch?
	
	@Binding var isExpanded: Bool
	
	@AppStorage("LiveGameBox.shouldAutoRefresh")
	var shouldAutoRefresh = false
	@AppStorage("LiveGameBox.shouldAutoShow")
	var shouldAutoShow = false
	
	@Environment(\.valorantLoad) private var load
	@EnvironmentObject private var settings: AppSettings
	
	var isInMatchmaking: Bool {
		party?.state == .inMatchmaking
	}
	
	var isAutoRefreshing: Bool {
		shouldAutoRefresh || isInMatchmaking
	}
	
	var body: some View {
		RefreshableBox(title: "Party", isExpanded: $isExpanded) {
			Divider()
			
			VStack(spacing: 16) {
				content
			}
			.padding(16)
		} refresh: { try await refresh(using: $0) }
			.onChange(of: activeMatch) { [activeMatch] newMatch in
				if shouldAutoRefresh, shouldAutoShow, activeMatch?.id != newMatch?.id {
					shownMatch = newMatch
				}
				if settings.vibrateOnMatchFound, activeMatch == nil, newMatch != nil {
					AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
				}
			}
	}
	
	@ViewBuilder
	private var content: some View {
		if let activeMatch {
			GroupBox {
				if activeMatch.inPregame {
					Text("Currently in agent select")
				} else {
					Text("Currently in-game")
				}
				
				Group {
					NavigationLink(tag: activeMatch, selection: $shownMatch) {
						LiveGameContainer(
							userID: userID,
							playersInParty: Set(party?.members.map(\.id) ?? []), 
							activeMatch: activeMatch
						)
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
		} else if party != nil { // i would like to use if let party = Binding($party), but that causes crashes internal to swiftui
			PartyInfoBox(userID: userID, party: Binding(
				get: { party! },
				set: { party = $0 }
			))
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
						await load(refresh)
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
	func refresh(using client: ValorantClient) async throws {
		// load independently & concurrently
		// TODO: change once `async let _ = ...` is fixed
		async let activeMatchUpdate: Void = loadActiveMatch(using: client)
		async let partyUpdate: Void = loadParty(using: client)
		_ = try await (activeMatchUpdate, partyUpdate)
	}
	
	func loadActiveMatch(using client: ValorantClient) async throws {
		activeMatch = try await client.getActiveMatch()
	}
	
	func loadParty(using client: ValorantClient) async throws {
		party = try await client.getPartyInfo()
		if let party {
			LocalDataProvider.dataFetched(party)
			try await client.fetchUsers(for: party.members.map(\.id))
		}
	}
}

#if DEBUG
struct LiveGameBox_Previews: PreviewProvider {
	static var previews: some View {
		Group {
			LiveGameBox(
				userID: PreviewData.userID,
				isExpanded: .constant(true),
				shouldAutoRefresh: true
			)
			LiveGameBox(
				userID: PreviewData.userID,
				party: PreviewData.party,
				isExpanded: .constant(true)
			)
		}
		.padding()
		.background(Color.groupedBackground)
		.previewLayout(.sizeThatFits)
		
		VStack(spacing: 16) {
			LiveGameBox(
				userID: PreviewData.userID,
				activeMatch: .init(id: Match.ID(), inPregame: true),
				isExpanded: .constant(true)
			)
			LiveGameBox(
				userID: PreviewData.userID,
				activeMatch: .init(id: Match.ID(), inPregame: false),
				isExpanded: .constant(true)
			)
			Spacer()
		}
		.padding()
		.background(Color.groupedBackground)
		.withToolbar()
	}
}
#endif
