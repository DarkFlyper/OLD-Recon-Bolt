import SwiftUI
import VisualEffects
import ValorantAPI

struct MatchDetailsHero: View {
	let matchDetails: MatchDetails
	let myself: Player?
	
	var body: some View {
		ZStack {
			let mapID = matchDetails.matchInfo.mapID
			MapImage.splash(mapID)
				.aspectRatio(contentMode: .fill)
				.frame(height: 150)
				.clipped()
				.overlay(MapImage.Label(mapID: mapID).padding(6))
			
			#if os(macOS)
			let blur = VisualEffectBlur(material: .toolTip, blendingMode: .withinWindow, state: .followsWindowActiveState)
			#else
			let blur = VisualEffectBlur(blurStyle: .systemThinMaterialDark)
			#endif
			
			VStack {
				scoreSummary(for: matchDetails.teams)
					.font(.largeTitle.weight(.heavy))
				
				Text(matchDetails.matchInfo.queueID.name)
					.font(.largeTitle.weight(.semibold).smallCaps())
					.opacity(0.8)
					.blendMode(.overlay)
			}
			.padding(.horizontal, 6)
			.background(
				blur.roundedAndStroked(cornerRadius: 8)
			)
			.shadow(radius: 10)
			.colorScheme(.dark)
		}
	}
	
	@ViewBuilder
	private func scoreSummary(for teams: [Team]) -> some View {
		let _ = assert(!teams.isEmpty)
		let sorted = teams.sorted {
			$0.id == myself?.teamID // self first
				|| $1.id != myself?.teamID // self first
				&& $0.pointCount > $1.pointCount // sort decreasingly by score
		}
		
		if sorted.count >= 2 {
			HStack {
				Text(verbatim: "\(sorted[0].pointCount)")
					.foregroundColor(.valorantBlue)
				Text("–")
					.opacity(0.5)
				Text(verbatim: "\(sorted[1].pointCount)")
					.foregroundColor(.valorantRed)
				
				if sorted.count > 2 {
					Text("–")
						.opacity(0.5)
					Text(verbatim: "…")
						.foregroundColor(.valorantRed)
				}
			}
		} else {
			Text(verbatim: "\(sorted[0].pointCount) points")
		}
	}
	
	private func scoreText(for team: Team) -> some View {
		Text(verbatim: "\(team.pointCount)")
			.foregroundColor(team.id.color)
	}
}

struct MatchDetailsHero_Previews: PreviewProvider {
	static var previews: some View {
		MatchDetailsHero(
			matchDetails: PreviewData.singleMatch,
			myself: PreviewData.singleMatch.players.first { $0.id == PreviewData.playerID }
		)
		.previewLayout(.sizeThatFits)
		.environmentObject(AssetManager.forPreviews)
	}
}
