import SwiftUI
import ValorantAPI

struct MatchDetailsHero: View {
	let data: MatchViewData
	
	var body: some View {
		ZStack {
			let mapID = data.details.matchInfo.mapID
			MapImage.splash(mapID)
				.aspectRatio(contentMode: .fill)
				.frame(height: 150)
				.clipped()
				.overlay(MapImage.Label(mapID: mapID).padding(6))
			
			VStack {
				scoreSummary(for: data.details.teams)
					.font(.largeTitle.weight(.heavy))
				
				Text(data.details.matchInfo.queueID.name)
					.font(.largeTitle.weight(.medium).smallCaps())
					.foregroundStyle(.secondary)
			}
			.padding(.horizontal, 6)
			.background(Material.thin)
			.cornerRadius(8)
			.shadow(radius: 10)
			.colorScheme(.dark)
		}
	}
	
	@ViewBuilder
	private func scoreSummary(for teams: [Team]) -> some View {
		let _ = assert(!teams.isEmpty)
		let sorted = teams.sorted(on: \.pointCount)
			.reversed()
			.movingToFront { $0.id == data.myself?.teamID }
		
		if sorted.count >= 2 {
			HStack {
				Text(verbatim: "\(sorted[0].pointCount)")
					.foregroundColor(.valorantBlue)
				Text("–")
					.foregroundStyle(.tertiary)
				Text(verbatim: "\(sorted[1].pointCount)")
					.foregroundColor(.valorantRed)
				
				if sorted.count > 2 {
					Text("–")
						.foregroundStyle(.tertiary)
					Text(verbatim: "…")
						.foregroundColor(.valorantRed)
				}
			}
		} else {
			Text(verbatim: "\(sorted[0].pointCount) points")
		}
	}
}

#if DEBUG
struct MatchDetailsHero_Previews: PreviewProvider {
	static var previews: some View {
		MatchDetailsHero(data: PreviewData.singleMatchData)
			.previewLayout(.sizeThatFits)
			.withPreviewAssets()
	}
}
#endif
