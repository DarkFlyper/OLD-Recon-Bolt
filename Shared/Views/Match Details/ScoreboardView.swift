import SwiftUI
import ValorantAPI

struct ScoreboardView: View {
	let players: [Player]
	let myself: Player?
	@Binding var highlightedPlayer: Player.ID?
	
	@State private var width: CGFloat = 0
	
	private let scoreboardPadding: CGFloat = 6
	
	var body: some View {
		let sorted = players.sorted { $0.stats.score > $1.stats.score }
		
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
	
	@ViewBuilder
	private func scoreboardRow(for player: Player) -> some View {
		let divider = Rectangle()
			.frame(width: 1)
			.blendMode(.destinationOut)
		let relativeColor = player.relativeColor(for: myself)
		
		HStack(spacing: 0) {
			let shouldFade = highlightedPlayer != nil && player.id != highlightedPlayer
			AgentImage.displayIcon(player.agentID)
				.frame(height: 40)
				.dynamicallyStroked(radius: 1, color: .white)
				.background(relativeColor.opacity(0.5))
				.compositingGroup()
				.opacity(shouldFade ? 0.5 : 1)
			
			HStack(spacing: scoreboardPadding) {
				Group {
					Text(verbatim: player.gameName)
						.fontWeight(.medium)
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
			// switch highlight to this player or toggle it off
			highlightedPlayer = highlightedPlayer == player.id ? nil : player.id
		}
	}
}

#if DEBUG
struct ScoreboardView_Previews: PreviewProvider {
	static var previews: some View {
		ScoreboardView(
			players: PreviewData.singleMatch.players,
			myself: PreviewData.singleMatch.players.first { $0.id == PreviewData.playerID },
			highlightedPlayer: .constant(nil)
		)
		.padding(.vertical)
		.inEachColorScheme()
		.environmentObject(AssetManager.forPreviews)
		.fixedSize(horizontal: true, vertical: true)
		.previewLayout(.sizeThatFits)
	}
}
#endif
