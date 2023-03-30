import SwiftUI
import ValorantAPI

struct RankChangesEntryProvider: FetchingIntentTimelineProvider {
	typealias Value = RankChangesInfo
	typealias Intent = ViewRankChangesIntent
	
	func fetchValue(in context: inout FetchingContext) async throws -> Value {
		let target = try context.configuration.account?.userID() ?? context.client.userID
		
		try await context.client.autoUpdateMatchList(for: target)
		let list = await LocalDataProvider.shared.matchListManager.cachedObject(for: target)!
		
		return .init(matches: list)
	}
}

struct CustomError: LocalizedError {
	var text: String
	
	var errorDescription: String? { text }
}

extension ViewRankChangesIntent: FetchingIntent {}

struct RankChangesInfo: FetchedTimelineValue {
	let matches: MatchList
	
	var nextRefresh: Date {
		.init(timeIntervalSinceNow: 60 * 60)
	}
}
