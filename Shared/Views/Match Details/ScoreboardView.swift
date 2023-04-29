import SwiftUI
import ValorantAPI

struct ScoreboardView: View {
	let data: MatchViewData
	@Binding var highlight: PlayerHighlightInfo
	
	@State private var width = 0.0
	@Environment(\.valorantLoad) private var load
	
	var body: some View {
		VStack {
			let sorted = data.details.players.sorted { $0.score > $1.score }
			
			ScrollView(.horizontal, showsIndicators: false) {
				VStack(spacing: ScoreboardRowView.padding) {
					ForEach(sorted) { player in
						ScoreboardRowView(player: player, data: data, highlight: $highlight)
					}
				}
				.padding(.horizontal)
				.frame(minWidth: width)
			}
			.measured { width = $0.width }
			
			AsyncButton(action: fetchRanks) {
				Text("Update Ranks", comment: "Match Details: button")
			}
			.buttonStyle(.bordered)
		}
	}
	
	private func fetchRanks() async {
		await load {
			for playerID in data.players.keys {
				try await $0.fetchCareerSummary(for: playerID)
			}
		}
	}
}

struct ScoreboardRowView: View {
	static let padding = 6.0
	private static let partyLetters = (UnicodeScalar("A").value...UnicodeScalar("Z").value)
		.map { String(UnicodeScalar($0)!) }
	
	let player: Player
	let data: MatchViewData
	@Binding var highlight: PlayerHighlightInfo
	
	@LocalData var summary: CareerSummary?
	
	@Environment(\.shouldAnonymize) private var shouldAnonymize
	
	var body: some View {
		let divider = Rectangle()
			.frame(width: 1)
			.blendMode(.destinationOut)
		let relativeColor = data.relativeColor(of: player)
		
		HStack(spacing: Self.padding) {
			ZStack {
				if let agentID = player.agentID {
					AgentImage.icon(agentID)
						.dynamicallyStroked(radius: 1, color: .white)
				} else {
					Image(systemName: "eye")
						.frame(maxWidth: .infinity, maxHeight: .infinity)
				}
			}
			.aspectRatio(1, contentMode: .fit)
			.background(relativeColor.opacity(0.5))
			.compositingGroup()
			.opacity(highlight.shouldFade(player.id) ? 0.5 : 1)
			
			HStack {
				identitySection
					.foregroundColor(relativeColor)
				
				divider
				
				ZStack {
					if let score = player.stats?.score {
						let roundsPlayed = data.details.roundResults.count
						Text(verbatim: "\(score / roundsPlayed)")
					} else {
						Text("–").foregroundStyle(.secondary)
					}
				}
				.frame(width: 60)
				
				divider
				
				KDASummaryView(player: player)
					.frame(width: 120)
				
				if !data.parties.isEmpty {
					divider
					
					partyLabel(for: player.partyID)
						.frame(width: 80)
				}
			}
			.padding(.vertical, Self.padding)
			
			relativeColor
				.frame(width: Self.padding)
		}
		.background(relativeColor.opacity(0.25))
		.frame(height: 44)
		.cornerRadius(Self.padding)
		.compositingGroup() // for the destination-out blending
		.onTapGesture {
			highlight.switchHighlight(to: player)
		}
		.withLocalData($summary, id: player.id)
	}
	
	@ViewBuilder
	var identitySection: some View {
		Group {
			if shouldAnonymize(player.id) {
				Text("Player")
					.foregroundStyle(.secondary)
			} else {
				Text(player.gameName)
			}
		}
		.font(.body.weight(
			highlight.isHighlighting(player.partyID)
				.map { $0 ? .semibold : .regular }
			?? .medium
		))
		.fixedSize()
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(.trailing, 4)
		
		Spacer()
		
		if player.id != data.myself?.id {
			TransparentNavigationLink {
				MatchListView(userID: player.id)
			} label: {
				Image(systemName: "person.crop.circle.fill")
					.frame(maxHeight: .infinity)
					.padding(.horizontal, 4)
			}
		}
		
		GeometryReader { geometry in
			RankInfoView(
				summary: summary,
				size: geometry.size.height,
				lineWidth: 2,
				shouldShowProgress: false,
				shouldFadeUnranked: true
			)
			.foregroundColor(nil)
		}
		.aspectRatio(1, contentMode: .fit)
	}
	
	func partyLabel(for party: Party.ID) -> some View {
		Group {
			if let partyIndex = data.parties.firstIndex(of: party) {
				let partyLetter = Self.partyLetters[partyIndex]
				let shouldEmphasize = highlight.isHighlighting(party) == true
				Text("Party \(partyLetter)", comment: "Scoreboard: party letter")
					.fontWeight(shouldEmphasize ? .medium : .regular)
			} else {
				Text("–")
			}
		}
		.opacity(highlight.shouldFade(party) ? 0.5 : 1)
	}
}

extension ScoreboardRowView {
	init(player: Player, data: MatchViewData, highlight: Binding<PlayerHighlightInfo>) {
		self.init(
			player: player, data: data, highlight: highlight,
			summary: .init(id: player.id)
		)
	}
}

#if DEBUG
struct ScoreboardView_Previews: PreviewProvider {
	static var previews: some View {
		Group {
			ScoreboardView(data: PreviewData.singleMatchData, highlight: .constant(.init()))
				.padding(.vertical)
			
			ScoreboardRowView(
				player: PreviewData.singleMatch.players[0],
				data: PreviewData.singleMatchData,
				highlight: .constant(.init())
			)
			.padding()
		}
		.fixedSize(horizontal: true, vertical: true)
		.previewLayout(.sizeThatFits)
	}
}
#endif
