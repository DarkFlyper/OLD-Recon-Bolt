import SwiftUI
import ValorantAPI

struct RankEntryProvider: FetchingIntentTimelineProvider {
	typealias Value = RankInfo
	typealias Intent = ViewRankIntent
	
	func fetchValue(in context: inout FetchingContext) async throws -> Value {
		let summary = try await context.client.getCareerSummary(userID: context.client.userID)
		
		let act = context.assets.seasons.currentAct()
		let info = summary.competitiveInfo?.inSeason(act?.id)
		let tier = info?.competitiveTier ?? 0
		let tierInfo = context.assets.seasons.tierInfo(number: tier, in: act)
		
		await tierInfo?.icon?.preload()
		
		return .init(
			summary: summary,
			tierInfo: tierInfo,
			//tierIcon: await tierInfo?.icon?.resolved(),
			rankedRating: info?.adjustedRankedRating ?? 0
		)
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
