import SwiftUI
import WidgetKit
import Intents
import ValorantAPI
import HandyOperators

struct StoreEntryProvider: FetchingIntentTimelineProvider {
	typealias Value = StorefrontInfo
	typealias Intent = ViewStoreIntent
	
	func fetchValue(in context: inout FetchingContext) async throws -> StorefrontInfo {
		context.link.destination = .store
		
		let store = try await context.client.getStorefront()
		let resolvedOffers = try store.dailySkinStore.offers.map { offer in
			let reward = try offer.rewards.first ??? UpdateError.malformedOffer
			return try context.assets.resolveSkin(.init(rawID: reward.itemID)) ??? UpdateError.unknownSkin
		}
		
		func fetchStuff(for resolved: ResolvedLevel) async -> StorefrontInfo.Skin {
			async let icon = resolved.displayIcon?.resolved()
			let tier: ContentTier? = resolved.skin.contentTierID.flatMap { x -> ContentTier? in context.assets.contentTiers[x] }
			async let tierIcon = tier?.displayIcon.resolved()
			return await StorefrontInfo.Skin(
				name: resolved.displayName,
				icon: icon,
				tierColor: tier?.color,
				tierIcon: tierIcon
			)
		}
		
		return StorefrontInfo(
			nextRefresh: Date(timeIntervalSinceNow: store.dailySkinStore.remainingDuration + 1),
			skins: await resolvedOffers.concurrentMap(fetchStuff(for:))
		)
	}
	
	enum UpdateError: Error, LocalizedError {
		case noAssets
		case unknownOffer
		case malformedOffer
		case unknownSkin
		
		var errorDescription: String? {
			switch self {
			case .noAssets:
				return String(localized: "Missing Assets!", table: "Errors", comment: "store widget error")
			case .unknownOffer:
				return String(localized: "Unknown Offer", table: "Errors", comment: "store widget error")
			case .malformedOffer:
				return String(localized: "Malformed Offer", table: "Errors", comment: "store widget error")
			case .unknownSkin:
				return String(localized: "Unknown Skin", table: "Errors", comment: "store widget error")
			}
		}
	}
}

extension ViewStoreIntent: SelfFetchingIntent {}

struct StorefrontInfo: FetchedTimelineValue {
	let nextRefresh: Date
	let skins: [Skin]
	
	struct Skin {
		var name: String
		var icon: Image?
		var tierColor: Color?
		var tierIcon: Image?
	}
}
