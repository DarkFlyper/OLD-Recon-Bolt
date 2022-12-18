import Foundation
import ValorantAPI

typealias MissionWithInfo = (mission: Mission, info: MissionInfo?)

struct ContractsEntryProvider: FetchingIntentTimelineProvider {
	typealias Value = ContractDetailsInfo
	typealias Intent = ViewMissionsIntent
	
	func fetchValue(in context: inout FetchingContext) async throws -> Value {
		let details = try await context.client.getContractDetails()
		return .init(
			contractDetails: details,
			missions: details.missions
				.map { ($0, context.assets.missions[$0.id]) },
			assets: context.assets
		)
	}
}

extension ViewMissionsIntent: SelfFetchingIntent {}

struct ContractDetailsInfo: FetchedTimelineValue {
	var contractDetails: ContractDetails
	var missions: [MissionWithInfo]
	var assets: AssetCollection?
	
	var nextRefresh: Date {
		let hour = Calendar.current.component(.hour, from: .now)
		// refresh each hour on the dot to keep countdown times accurate to the hour
		let nextHour = Calendar.current.date(bySettingHour: hour + 1, minute: 0, second: 0, of: .now)!
		return min(
			missions
				.first { $0.info?.type == .daily }?
				.mission.expirationTime
			?? .distantFuture,
			nextHour
		)
	}
}
