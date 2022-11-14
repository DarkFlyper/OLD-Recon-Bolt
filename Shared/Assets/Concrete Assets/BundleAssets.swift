import Foundation
import ValorantAPI

extension AssetClient {
	func getBundleInfo() async throws -> [StoreBundleInfo] {
		try await send(BundleInfoRequest())
	}
}

private struct BundleInfoRequest: AssetDataRequest {
	let path = "/v1/bundles"
	
	typealias Response = [StoreBundleInfo]
}

struct StoreBundleInfo: AssetItem, Codable, Identifiable {
	private var uuid: ID
	var id: StoreBundle.Asset.ID { uuid }
	var displayName: String
	var displayNameSubtext: String?
	var description: String
	var extraDescription: String?
	var promoDescription: String?
	var useAdditionalContext: Bool
	var displayIcon: AssetImage
	var displayIcon2: AssetImage
	var verticalPromoImage: AssetImage?
}
