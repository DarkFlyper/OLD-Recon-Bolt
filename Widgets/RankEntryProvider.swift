import SwiftUI
import ValorantAPI

struct RankEntryProvider: FetchingIntentTimelineProvider {
	typealias Value = RankInfo
	typealias Intent = ViewRankIntent
	
	func fetchValue(in context: inout FetchingContext) async throws -> Value {
		let summary = try await context.client.getCareerSummary(userID: context.client.userID)
		
		let act = context.assets.seasons.currentAct()
		let seasonInfo = summary.competitiveInfo?.inSeason(act?.id)
		let tier = seasonInfo?.competitiveTier ?? 0
		let tierInfo = context.assets.seasons.tierInfo(number: tier, in: act)
		
		let rankInfo = RankInfo(
			summary: summary,
			tierInfo: tierInfo,
			rankedRating: seasonInfo?.adjustedRankedRating ?? 0
		)
		
		await preloadImages {
			RankEntryView(entry: .init(info: .success(rankInfo)))
		}
		
		return rankInfo
	}
}

@MainActor
func preloadImages<Content: View>(@ViewBuilder usedIn views: () -> Content) async {
	ImageRenderer(content: ZStack(content: views)).render { _, _ in }
	
	_ = await AssetImage.used.concurrentMap { image in
		await image.preload()
	}
}

// TODO: should be FetchingIntent, allowing bookmarks as well
extension ViewRankIntent: SelfFetchingIntent {}

struct RankInfo: FetchedTimelineValue {
	let summary: CareerSummary
	let tierInfo: CompetitiveTier?
	//let tierIcon: Image?
	let rankedRating: Int
	
	var nextRefresh: Date {
		.init(timeIntervalSinceNow: 60 * 60)
	}
}
