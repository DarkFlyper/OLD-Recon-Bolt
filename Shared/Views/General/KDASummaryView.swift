import SwiftUI
import ValorantAPI

struct KDASummaryView: View {
	let player: Player
	
	var body: some View {
		HStack {
			Text("\(player.stats.kills)")
			Text("/").foregroundStyle(.secondary)
			Text("\(player.stats.deaths)")
			Text("/").foregroundStyle(.secondary)
			Text("\(player.stats.assists)")
		}
	}
}
