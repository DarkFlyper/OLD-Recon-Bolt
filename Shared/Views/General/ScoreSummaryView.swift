import SwiftUI
import ValorantAPI

struct ScoreSummaryView: View {
	let teams: [Team]
	let ownTeamID: Team.ID?
	
	var body: some View {
		let _ = assert(!teams.isEmpty)
		let sorted = teams.sorted(on: \.pointCount)
			.reversed()
			.movingToFront { $0.id == ownTeamID }
		
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
