import SwiftUI
import ValorantAPI

struct ScoreboardView: View {
	let players: [Player]
	let myself: Player?
	
	@State private var width: CGFloat = 0
	
	private let scoreboardPadding: CGFloat = 6
	
	var body: some View {
		let sorted = players.sorted { $0.stats.score > $1.stats.score }
		
		ScrollView(.horizontal) {
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
		let teamColor = color(for: player.teamID) ?? .valorantBlue
		let teamOrSelfColor = player.id == myself?.id ? .valorantSelf : teamColor
		
		HStack(spacing: 0) {
			AgentImage.displayIcon(player.agentID)
				.frame(height: 40)
				.dynamicallyStroked(radius: 1, color: .white)
				.background(teamOrSelfColor.opacity(0.5))
			
			HStack(spacing: scoreboardPadding) {
				Group {
					Text(verbatim: player.gameName)
						.fontWeight(.medium)
						.foregroundColor(teamOrSelfColor)
						.fixedSize()
						.frame(maxWidth: .infinity, alignment: .leading)
					
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
			
			teamOrSelfColor
				.frame(width: scoreboardPadding)
		}
		.background(teamOrSelfColor.opacity(0.25))
		.cornerRadius(scoreboardPadding)
	}
	
	private func color(for teamID: Team.ID) -> Color? {
		if let own = myself?.teamID {
			return teamID == own ? .valorantBlue : .valorantRed
		} else {
			return teamID.color
		}
	}
}

struct ScoreboardView_Previews: PreviewProvider {
	static var previews: some View {
		ScoreboardView(
			players: PreviewData.singleMatch.players,
			myself: PreviewData.singleMatch.players.first { $0.id == PreviewData.playerID }
		)
		.padding(.vertical)
		.inEachColorScheme()
		.environmentObject(AssetManager.forPreviews)
		.fixedSize(horizontal: true, vertical: true)
		.previewLayout(.sizeThatFits)
	}
}
