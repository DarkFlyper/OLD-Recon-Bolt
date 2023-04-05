import SwiftUI
import ValorantAPI

struct RankEntryProvider: FetchingIntentTimelineProvider {
	typealias Value = RankInfo
	typealias Intent = ViewRankIntent
	
	func fetchValue(in context: inout FetchingContext) async throws -> Value {
		let target = try context.configuration.account?.userID()
		context.link.destination = .career(target)
		let summary = try await context.client.getCareerSummary(userID: target)
		
		let act = context.seasons.currentAct()
		let seasonInfo = summary.competitiveInfo?.inSeason(act?.id)
		let tier = seasonInfo?.competitiveTier
		let tierInfo = context.seasons.tierInfo(number: tier, in: act)
		
		return .init(
			summary: summary,
			tierInfo: tierInfo,
			rankedRating: seasonInfo?.adjustedRankedRating ?? 0
		)
	}
}

extension ViewRankIntent: FetchingIntent {}

struct RankInfo: FetchedTimelineValue {
	let summary: CareerSummary
	let tierInfo: CompetitiveTier?
	let rankedRating: Int
	
	var nextRefresh: Date {
		.init(timeIntervalSinceNow: 60 * 60)
	}
}
