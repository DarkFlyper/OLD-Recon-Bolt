import SwiftUI
import ValorantAPI

struct KDASummaryView: View {
	let player: Player
	
	var body: some View {
		if let stats = player.stats {
			HStack {
				Text("\(stats.kills)")
				Text("/").foregroundStyle(.secondary)
				Text("\(stats.deaths)")
				Text("/").foregroundStyle(.secondary)
				Text("\(stats.assists)")
			}
		} else {
			Text("Spectator")
				.foregroundStyle(.secondary)
		}
	}
}
