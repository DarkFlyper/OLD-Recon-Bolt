import SwiftUI
import ValorantAPI

struct SeasonLabel: View {
	let season: Act.ID?
	
	@Environment(\.assets) private var assets
	
	var body: some View {
		if let season, let act = assets?.seasons.acts[season] {
			HStack {
				if let episode = act.episode {
					Text(episode.name.replacingOccurrences(of: "EPISODE", with: "EP"))
						.fontWeight(.medium)
					Text("//")
						.foregroundStyle(.tertiary)
				}
				Text(act.name)
			}
			.foregroundStyle(.secondary)
		}
	}
}

struct PeakRankIcon: View {
	var peakRank: RankSnapshot
	var tierInfo: CompetitiveTier
	var size: CGFloat
	
	@Environment(\.assets) private var assets
	@Environment(\.colorScheme) private var colorScheme
	
	var body: some View {
		ZStack {
			// this border helps add some padding to the rank triangle to justify showing it at a smaller size, hiding the low resolution
			assets?.seasons.acts[peakRank.season]?
				.borders.last?.fullImage.view()
				.opacity(colorScheme == .dark ? 0.4 : 1) // it's very light, so this helps maintain the same contrast
			
			tierInfo.rankTriangleUpwards?.view(shouldLoadImmediately: true)
				.scaleEffect(0.65, anchor: .init(x: 0.5, y: 0.5)) // visually tweaked to look just right
				.shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 4)
				.alignmentGuide(.rankIcon) { $0[VerticalAlignment.center] }
		}
		.frame(width: size, height: size)
	}
}

extension VerticalAlignment {
	static let rankIcon = Self(NewID.self)
	
	private enum NewID: AlignmentID {
		static func defaultValue(in context: ViewDimensions) -> CGFloat {
			context.height / 2
		}
	}
}
