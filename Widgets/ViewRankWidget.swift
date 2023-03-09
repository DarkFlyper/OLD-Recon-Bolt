import SwiftUI
import WidgetKit
import Intents
import ValorantAPI
import HandyOperators

struct ViewRankWidget: Widget {
	var body: some WidgetConfiguration {
		IntentConfiguration.preloading(
			kind: "view rank",
			intent: ViewRankIntent.self,
			provider: RankEntryProvider(),
			supportedFamilies: .systemSmall
		) { entry in
			RankEntryView(entry: entry)
		}
		.configurationDisplayName("Rank")
		.description("View your current rank.")
	}
}

struct RankEntryView: TimelineEntryView {
	var entry: RankEntryProvider.Entry
	
	@Environment(\.adjustedWidgetFamily) private var widgetFamily
	
	func contents(for info: RankInfo) -> some View {
		VStack {
			GeometryReader { geometry in
				RankInfoView(
					summary: info.summary,
					size: geometry.size.height,
					lineWidth: geometry.size.height / 16,
					shouldFallBackOnPrevious: true
				)
				.frame(maxWidth: .infinity)
			}
			
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
