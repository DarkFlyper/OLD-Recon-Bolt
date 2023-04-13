import SwiftUI
import ValorantAPI

struct RankChangesEntryProvider: FetchingIntentTimelineProvider {
	typealias Value = RankChangesInfo
	typealias Intent = ViewRankChangesIntent
	
	func fetchValue(in context: inout FetchingContext) async throws -> Value {
		let target = try context.configuration.account?.userID()
		context.link.destination = .career(target)
		let userID = target ?? context.client.userID
		
		try await context.client.autoUpdateMatchList(for: userID)
		let list = await LocalDataProvider.shared.matchListManager.cachedObject(for: userID)!
		
		return .init(matches: list)
	}
}

extension ViewRankChangesIntent: FetchingIntent {}

struct RankChangesInfo: FetchedTimelineValue {
	let matches: MatchList
	
	var nextRefresh: Date {
		.init(timeIntervalSinceNow: 60 * 60)
	}
}
