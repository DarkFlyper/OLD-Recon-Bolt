import SwiftUI
import ValorantAPI

struct ScoreboardView: View {
	let data: MatchViewData
	@Binding var highlight: PlayerHighlightInfo
	
	@State private var width: CGFloat = 0
	
	private let scoreboardPadding: CGFloat = 6
	
	var body: some View {
		let sorted = data.details.players.sorted { $0.stats.score > $1.stats.score }
		
		ScrollView(.horizontal, showsIndicators: false) {
			VStack(spacing: scoreboardPadding) {
				ForEach(sorted) { player in
					scoreboardRow(for: player)
				}
			}
			.padding(.horizontal)
			.frame(minWidth: width)
		}
		.measured { width = $0.width }
	}
	
	private static let partyLetters = (UnicodeScalar("A").value...UnicodeScalar("Z").value)
		.map { String(UnicodeScalar($0)!) }
	
	@ViewBuilder
	private func scoreboardRow(for player: Player) -> some View {
		let divider = Rectangle()
			.frame(width: 1)
			.blendMode(.destinationOut)
		let relativeColor = data.relativeColor(of: player)
		
		HStack(spacing: 0) {
			AgentImage.displayIcon(player.agentID)
				.frame(height: 40)
				.dynamicallyStroked(radius: 1, color: .white)
				.background(relativeColor.opacity(0.5))
				.compositingGroup()
				.opacity(highlight.shouldFade(player.id) ? 0.5 : 1)
			
			HStack(spacing: scoreboardPadding) {
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
					
					divider
					
					Text(verbatim: "\(player.stats.score)")
						.frame(width: 60)
					
					divider
					
					HStack {
						Text(verbatim: "\(player.stats.kills)")
						Text("/").opacity(0.5)
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
				.frame(maxHeight: .infinity)
			}
			.padding(scoreboardPadding)
			
			relativeColor
				.frame(width: scoreboardPadding)
		}
		.background(relativeColor.opacity(0.25))
		.cornerRadius(scoreboardPadding)
		.onTapGesture {
			highlight.switchHighlight(to: player)
		}
	}
}

#if DEBUG
struct ScoreboardView_Previews: PreviewProvider {
	static var previews: some View {
		ScoreboardView(data: PreviewData.singleMatchData, highlight: .constant(.init()))
			.padding(.vertical)
			.inEachColorScheme()
			.environmentObject(AssetManager.forPreviews)
			.fixedSize(horizontal: true, vertical: true)
			.previewLayout(.sizeThatFits)
	}
}
#endif
