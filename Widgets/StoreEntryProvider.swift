import SwiftUI
import WidgetKit
import Intents
import ValorantAPI
import HandyOperators

struct StoreEntryProvider: FetchingIntentTimelineProvider {
	typealias Value = StorefrontInfo
	typealias Intent = ViewStoreIntent
	
	func fetchValue(in context: inout FetchingContext) async throws -> StorefrontInfo {
		let store = try await context.client.getStorefront()
		let offers = Dictionary(values: try await context.client.getStoreOffers())
		let resolvedOffers = try store.skinsPanelLayout.singleItemOffers.map { offerID in
			let offer = try offers[offerID] ??? UpdateError.unknownOffer
			let reward = try offer.rewards.first ??? UpdateError.malformedOffer
			return try context.assets.resolveSkin(.init(rawID: reward.itemID)) ??? UpdateError.unknownSkin
		}
		
		let images = try await withThrowingTaskGroup(of: (WeaponSkin.Level.ID, Image?).self, returning: [WeaponSkin.Level.ID: Image].self) { group in
			for resolved in resolvedOffers {
				group.addTask {
					if let icon = resolved.displayIcon {
						// TODO: why does this sometimes fail initially, but only for some images?
						let image = await Managers.images.awaitImage(for: icon)
						return (resolved.id, image.map(Image.init))
					} else {
						return (resolved.id, nil)
					}
				}
			}
			var images: [WeaponSkin.Level.ID: Image] = [:]
			for try await (offer, image) in group {
				images[offer] = image
			}
			return images
		}
		
		return .init(
			nextRefresh: Date(timeIntervalSinceNow: store.skinsPanelLayout.remainingDuration + 1),
			skins: resolvedOffers.map { resolved in
				return .init(name: resolved.displayName, icon: images[resolved.id])
			}
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
				return "Missing Assets!"
			case .unknownOffer:
				return "Unknown Offer"
			case .malformedOffer:
				return "Malformed Offer"
			case .unknownSkin:
				return "Unknown Skin"
			}
		}
	}
}

typealias StoreEntry = FetchedTimelineEntry<StorefrontInfo, ViewStoreIntent>

extension ViewStoreIntent: SelfFetchingIntent {}

struct StorefrontInfo: FetchedTimelineValue {
	let nextRefresh: Date
	let skins: [Skin]
	
	struct Skin {
		var name: String
		var icon: Image?
	}
}
