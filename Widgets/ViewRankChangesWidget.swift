import SwiftUI
import WidgetKit
import Intents
import ValorantAPI

struct ViewRankChangesWidget: Widget {
	var body: some WidgetConfiguration {
		IntentConfiguration.preloading(
			kind: .viewRankChanges,
			intent: ViewRankChangesIntent.self,
			provider: RankChangesEntryProvider()
		) { entry in
			RankChangesEntryView(entry: entry)
				.reloadingOnTap(.viewRankChanges)
				.environment(\.location, entry.location)
		}
		.supportedFamilies([.systemSmall, .systemMedium])
		.configurationDisplayName(Text("Rank Changes", comment: "Rank Changes Widget: title"))
		.description(Text("View your rank rating changes.", comment: "Rank Changes Widget: description"))
	}
}

struct RankChangesEntryView: TimelineEntryView {
	let entry: RankChangesEntryProvider.Entry
	
	@Environment(\.adjustedWidgetFamily) private var widgetFamily
	
	var isSmall: Bool {
		widgetFamily == .systemSmall
	}
	
	func contents(for info: RankChangesInfo) -> some View {
		RankRatingChart(
			matches: info.matches.matches,
			maxCount: isSmall ? 10 : 20
		)
	}
}

#if DEBUG
struct ViewRankChangesWidget_Previews: PreviewProvider {
	static var previews: some View {
		let view = RankChangesEntryView(entry: .mocked(
			value: .init(matches: PreviewData.matchList)
		))
			.environmentObject(GameConfigManager())
			.environment(\.location, .europe)
		
		view.previewContext(WidgetPreviewContext(family: .systemSmall))
			.previewDisplayName("Small")
		
		view.previewContext(WidgetPreviewContext(family: .systemMedium))
			.previewDisplayName("Medium")
	}
}
#endif
