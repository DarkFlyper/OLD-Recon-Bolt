import SwiftUI
import ValorantAPI

struct GameModeImage: View {
	var id: GameMode.ID
	
	@Environment(\.assets) private var assets
	
	var body: some View {
		assets?.gameModes[id]
			.flatMap(\.displayIcon)?
			.view(renderingMode: .template, shouldLoadImmediately: true)
	}
}

#if DEBUG
struct GameModeImage_Previews: PreviewProvider {
	static var previews: some View {
		VStack {
			ForEach([
				GameMode.ID.standard, .spikeRush, .deathmatch,
				.snowballFight, .escalation, .replication,
				.onboarding, .practice,
			], id: \.self) { mode in
				GameModeImage(id: mode)
				Text(mode.rawValue)
				Divider()
			}
		}
		.fixedSize()
		.padding()
		.previewLayout(.sizeThatFits)
	}
}
#endif
