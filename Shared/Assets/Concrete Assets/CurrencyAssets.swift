import Foundation
import ValorantAPI

extension AssetClient {
	func getCurrencyInfo() async throws -> [CurrencyInfo] {
		try await send(CurrencyInfoRequest())
	}
}

private struct CurrencyInfoRequest: AssetDataRequest {
	let path = "/v1/currencies"
	
	typealias Response = [CurrencyInfo]
}

struct CurrencyInfo: AssetItem, Codable, Identifiable {
	var id: Currency.ID
	var displayNamePlural: String
	var displayNameSingular: String
	var displayIcon: AssetImage
	//var largeIcon: AssetImage
	
	private enum CodingKeys: String, CodingKey {
		case id = "uuid"
		case displayNamePlural = "displayName"
		case displayNameSingular = "displayNameSingular"
		case displayIcon
		//case largeIcon
	}
}
