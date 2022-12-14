import SwiftUI
import WidgetKit
import Intents
import ValorantAPI
import HandyOperators

struct StoreEntryProvider: IntentTimelineProvider {
	@MainActor private static let accountManager = AccountManager()
	@MainActor private static let assetManager = AssetManager()
	// TODO: this storage should really be shared with the main app somehow…
	@MainActor private static let imageManager = ImageManager()
	
	func placeholder(in context: Context) -> StoreEntry {
		.mocked(info: .failure(FakeError.blankPreview))
	}
	
	func getSnapshot(for configuration: ViewStoreIntent, in context: Context, completion: @escaping (StoreEntry) -> ()) {
		Task {
			completion(await getCurrentEntry(for: configuration))
		}
	}
	
	func getTimeline(for configuration: ViewStoreIntent, in context: Context, completion: @escaping (Timeline<StoreEntry>) -> ()) {
		Task {
			let entry = await getCurrentEntry(for: configuration)
			let timeline = Timeline(entries: [entry], policy: .after(entry.nextRefresh()))
			completion(timeline)
		}
	}
	
	private func getCurrentEntry(for configuration: ViewStoreIntent) async -> StoreEntry {
		var link = WidgetLink(destination: .store)
		let result: Result<StorefrontInfo, Error>
		do {
			let account: StoredAccount
			if configuration.useActiveAccount != 0 {
				account = try await Self.accountManager.activeAccount ??? UpdateError.missingAccount
			} else {
				let rawAccount = try configuration.account ??? UpdateError.missingAccount
				let accountID = try rawAccount.identifier.flatMap(User.ID.init(_:)) ??? UpdateError.malformedAccount
				account = try await Self.accountManager.loadAccount(for: accountID)
			}
			link.account = account.session.userID
			let info = try await getCurrentInfo(using: account.client)
			result = .success(info)
		} catch {
			print(error)
			result = .failure(error)
		}
		return .init(date: .now, info: result, configuration: configuration, link: link)
	}
	
	private func getCurrentInfo(using client: ValorantClient) async throws -> StorefrontInfo {
		let store = try await client.getStorefront()
		let offers = Dictionary(values: try await client.getStoreOffers())
		await Self.assetManager.loadAssets()
		let assets = try await Self.assetManager.assets ??? UpdateError.noAssets
		let resolvedOffers = try store.skinsPanelLayout.singleItemOffers.map { offerID in
			let offer = try offers[offerID] ??? UpdateError.unknownOffer
			let reward = try offer.rewards.first ??? UpdateError.malformedOffer
			return try assets.resolveSkin(.init(rawID: reward.itemID)) ??? UpdateError.unknownSkin
		}
		
		let images = try await withThrowingTaskGroup(of: (WeaponSkin.Level.ID, Image?).self, returning: [WeaponSkin.Level.ID: Image].self) { group in
			for resolved in resolvedOffers {
				group.addTask {
					if let icon = resolved.displayIcon {
						await Self.imageManager.download(icon)
						return (resolved.id, await Self.imageManager.image(for: icon).map(Image.init))
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
		case missingAccount
		case malformedAccount
		case unknownAccountID(User.ID)
		case noAssets
		case unknownOffer
		case malformedOffer
		case unknownSkin
		
		var errorDescription: String? {
			switch self {
			case .missingAccount:
				return "Missing Account!"
			case .malformedAccount:
				return "Malformed Account"
			case .unknownAccountID(let id):
				return "Missing Account for ID \(id)"
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

struct StoreEntry: TimelineEntry {
	var date: Date
	var info: Result<StorefrontInfo, Error>
	var configuration: ViewStoreIntent
	var link: WidgetLink
	
	static func mocked(info: Result<StorefrontInfo, Error>, configuration: ViewStoreIntent? = nil) -> Self {
		.init(
			date: .now,
			info: info,
			configuration: configuration ?? .init(),
			link: .init()
		)
	}
	
	func nextRefresh() -> Date {
		do {
			return try info.get().nextRefresh
		} catch APIError.rateLimited(let retryAfter) {
			return .init(timeIntervalSinceNow: .init(retryAfter ?? 60))
		} catch is APIError {
			// TODO: trigger refresh from the app when this fails? might be hard to detect, but it might also be fine to just refresh on launch?
			return .init(timeIntervalSinceNow: 3600)
		} catch is URLError {
			return .init(timeIntervalSinceNow: 120) // likely connection failure; retry when connection is likely to be back
		} catch {
			return .init(timeIntervalSinceNow: 300) // decent default timeout
		}
	}
}

struct StorefrontInfo {
	let nextRefresh: Date
	let skins: [Skin]
	
	struct Skin {
		var name: String
		var icon: Image?
	}
}
