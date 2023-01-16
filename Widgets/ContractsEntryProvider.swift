import Foundation
import ValorantAPI

struct ContractsEntryProvider: FetchingIntentTimelineProvider {
	typealias Value = ContractDetailsInfo
	typealias Intent = ViewMissionsIntent
	
	func fetchValue(in context: inout FetchingContext) async throws -> Value {
		let details = try await context.client.getContractDetails()
		return .init(
			contracts: .init(details: details, assets: context.assets)
		)
	}
}

extension ViewMissionsIntent: SelfFetchingIntent {}

struct ContractDetailsInfo: FetchedTimelineValue {
	var contracts: ResolvedContracts
	
	var nextRefresh: Date {
		let hour = Calendar.current.component(.hour, from: .now)
		// refresh each hour on the dot to keep countdown times accurate to the hour
		let nextHour = Calendar.current.date(bySettingHour: hour + 1, minute: 0, second: 0, of: .now)!
		return min(
			contracts.dailyRefresh ?? .distantFuture,
			nextHour
		)
	}
}
