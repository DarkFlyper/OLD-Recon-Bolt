import SwiftUI
import WidgetKit
import Intents
import ValorantAPI
import HandyOperators

struct ViewRankWidget: Widget {
	var body: some WidgetConfiguration {
		// TODO: maybe wrap provider or something here with preloading functionality?
		IntentConfiguration(
			kind: "view rank",
			intent: ViewRankIntent.self,
			provider: RankEntryProvider()
		) { entry in
			RankEntryView(entry: entry)
		}
		.supportedFamilies([.systemSmall])
		.configurationDisplayName("Rank")
		.description("View your current rank.")
	}
}

struct RankEntryView: TimelineEntryView {
	var entry: RankEntryProvider.Entry
	
	@Environment(\.widgetFamily) private var widgetFamily
	
	func contents(for info: RankInfo) -> some View {
		VStack {
			RankInfoView(summary: info.summary, size: 96, lineWidth: 6, shouldFallBackOnPrevious: true)
			
			if entry.configuration.showRankName != 0, let tierInfo = info.tierInfo {
				Text(tierInfo.name)
					.font(.callout.weight(.semibold))
			}
			
			if entry.configuration.showRankRating != 0 {
				Text("\(info.rankedRating) RR")
					.font(.caption)
			}
		}
		.padding()
	}
}

#if DEBUG
struct ViewRankWidget_Previews: PreviewProvider {
	static let seasons = Managers.assets.assets?.seasons
	
	static var previews: some View {
		let view = RankEntryView(entry: .init(
			info: .success(.init(
				summary: PreviewData.summary,
				tierInfo: seasons?.currentTierInfo(number: 22),
				rankedRating: 69
			))
		))
		
		view.previewContext(WidgetPreviewContext(family: .systemSmall))
			.previewDisplayName("Small")
	}
}
#endif
