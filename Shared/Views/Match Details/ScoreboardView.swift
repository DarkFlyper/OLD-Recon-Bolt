import SwiftUI
import ValorantAPI

private let scoreboardPadding = 6.0

struct ScoreboardView: View {
	let data: MatchViewData
	@Binding var highlight: PlayerHighlightInfo
	
	@State private var width = 0.0
	@Environment(\.valorantLoad) private var load
	
	var body: some View {
		VStack {
			let sorted = data.details.players.sorted { $0.stats.score > $1.stats.score }
			
			ScrollView(.horizontal, showsIndicators: false) {
				VStack(spacing: scoreboardPadding) {
					ForEach(sorted) { player in
						ScoreboardRowView(player: player, data: data, highlight: $highlight)
					}
				}
				.padding(.horizontal)
				.frame(minWidth: width)
			}
			.measured { width = $0.width }
			
			AsyncButton("Fetch Missing Ranks", action: fetchRanks)
				.buttonStyle(.bordered)
		}
	}
	
	private func fetchRanks() async {
		await load { client in
			for playerID in data.players.keys {
				try await LocalDataProvider.shared.fetchCompetitiveSummary(for: playerID, using: client)
			}
		}
	}
}

struct ScoreboardRowView: View {
	private static let partyLetters = (UnicodeScalar("A").value...UnicodeScalar("Z").value)
		.map { String(UnicodeScalar($0)!) }
	
	let player: Player
	let data: MatchViewData
	@Binding var highlight: PlayerHighlightInfo
	
	@State private var summary: CompetitiveSummary?

	var body: some View {
		let divider = Rectangle()
			.frame(width: 1)
			.blendMode(.destinationOut)
		let relativeColor = data.relativeColor(of: player)
		
		HStack(spacing: 0) {
			AgentImage.displayIcon(player.agentID)
				.aspectRatio(1, contentMode: .fit)
				.dynamicallyStroked(radius: 1, color: .white)
				.background(relativeColor.opacity(0.5))
				.compositingGroup()
				.opacity(highlight.shouldFade(player.id) ? 0.5 : 1)
			
			HStack(spacing: scoreboardPadding) {
				Group {
					Group {
						Text(verbatim: player.gameName)
							.fontWeight(
								highlight.isHighlighting(player.partyID)
									.map { $0 ? .semibold : .regular }
									?? .medium
							)
							.foregroundColor(relativeColor)
							.fixedSize()
							.frame(maxWidth: .infinity, alignment: .leading)
							.padding(.trailing, 4)
						
						Spacer()
						
						if player.id != data.myself?.id {
							NavigationLink(destination: UserView(for: User(player))) {
								Image(systemName: "person.crop.circle.fill")
									.padding(.horizontal, 4)
							}
							.foregroundColor(relativeColor)
						}
					}
					
					RankInfoView(summary: summary, lineWidth: 2, shouldShowProgress: false, shouldFadeUnranked: true)
					
					divider
					
					Group {
						Text(verbatim: "\(player.stats.score)")
							.frame(width: 60)
						
						divider
						
						HStack {
							Text(verbatim: "\(player.stats.kills)")
							Text("/").foregroundStyle(.secondary)
							Text(verbatim: "\(player.stats.deaths)")
							Text("/").opacity(0.5)
							Text(verbatim: "\(player.stats.assists)")
						}
						.frame(width: 120)
						
						if !data.parties.isEmpty {
							divider
							
							Group {
								if let partyIndex = data.parties.firstIndex(of: player.partyID) {
									let partyLetter = Self.partyLetters[partyIndex]
									let shouldEmphasize = highlight.isHighlighting(player.partyID) == true
									Text("Party \(partyLetter)")
										.fontWeight(shouldEmphasize ? .medium : .regular)
								} else {
									Text("–")
								}
							}
							.opacity(highlight.shouldFade(player.partyID) ? 0.5 : 1)
							.frame(width: 80)
						}
					}
				}
				.frame(maxHeight: .infinity)
			}
			.padding(scoreboardPadding)
			
			relativeColor
				.frame(width: scoreboardPadding)
		}
		.frame(height: 44)
		.background(relativeColor.opacity(0.25))
		.cornerRadius(scoreboardPadding)
		.compositingGroup() // for the destination-out blending
		.onTapGesture {
			highlight.switchHighlight(to: player)
		}
		.withLocalData($summary) { $0.competitiveSummary(for: player.id) }
	}
}

#if DEBUG
struct ScoreboardView_Previews: PreviewProvider {
	static var previews: some View {
		ScoreboardView(data: PreviewData.singleMatchData, highlight: .constant(.init()))
			.padding(.vertical)
			.inEachColorScheme()
			.fixedSize(horizontal: true, vertical: true)
			.previewLayout(.sizeThatFits)
	}
}
#endif
