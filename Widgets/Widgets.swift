import WidgetKit
import SwiftUI
import Intents
import ValorantAPI
import HandyOperators
import Algorithms
import CGeometry

struct Provider: IntentTimelineProvider {
	@MainActor private static let accountManager = AccountManager()
	@MainActor private static let assetManager = AssetManager()
	// TODO: this storage should really be shared with the main app somehow…
	@MainActor private static let imageManager = ImageManager()
	
	func placeholder(in context: Context) -> StoreEntry {
		fatalError() // TODO
	}
	
	func getSnapshot(for configuration: ViewStoreIntent, in context: Context, completion: @escaping (StoreEntry) -> ()) {
		Task {
			completion(await getCurrentEntry(for: configuration))
		}
	}
	
	func getTimeline(for configuration: ViewStoreIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
		Task {
			let entry = await getCurrentEntry(for: configuration)
			let timeline = Timeline(entries: [entry], policy: .after(entry.nextRefresh()))
			completion(timeline)
		}
	}
	
	private func getCurrentEntry(for configuration: ViewStoreIntent) async -> StoreEntry {
		let result: Result<StorefrontInfo, Error>
		do {
			let rawAccount = try configuration.account ??? UpdateError.noAccountFound
			let accountID = try rawAccount.identifier.flatMap(User.ID.init(_:)) ??? UpdateError.malformedAccount
			let account = try await Self.accountManager.loadAccount(for: accountID)
			let info = try await getCurrentInfo(using: account.client)
			result = .success(info)
		} catch {
			print(error)
			result = .failure(error)
		}
		return .init(date: .now, info: result, configuration: configuration)
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
		case noAccountFound
		case malformedAccount
		case unknownAccountID(User.ID)
		case noAssets
		case unknownOffer
		case malformedOffer
		case unknownSkin
		
		var errorDescription: String? {
			switch self {
			case .noAccountFound:
				return "No Account Found!"
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

final class ViewStoreHandler: NSObject, ViewStoreIntentHandling {
	func provideAccountOptionsCollection(for intent: ViewStoreIntent) async throws -> INObjectCollection<Account> {
		return INObjectCollection(items: [Account(identifier: "asdf", display: "Failed!")])
	}
}

struct StoreEntry: TimelineEntry {
	var date: Date
	var info: Result<StorefrontInfo, Error>
	var configuration: ViewStoreIntent
	
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

struct Widgets: Widget {
	let kind: String = "Widgets"
	
	var body: some WidgetConfiguration {
		IntentConfiguration(kind: kind, intent: ViewStoreIntent.self, provider: Provider()) { entry in
			StoreEntryView(entry: entry)
			// TODO: somehow deep link to store on tap — including switching to active account!
		}
		.supportedFamilies([.systemMedium, .systemLarge])
		.configurationDisplayName("Store")
		.description("Check your current Valorant storefront.")
	}
}

extension AccentColor {
	var color: Color {
		switch self {
		case .unknown:
			fallthrough
		case .red:
			return .valorantRed
		case .blue:
			return .valorantBlue
		case .highlight:
			return .valorantSelf
		}
	}
}

struct StoreEntryView: View {
	var entry: StoreEntry
	
	let opacities = [0.2, 0.3]
	
	@Environment(\.widgetFamily) private var widgetFamily
	
	var body: some View {
		switch entry.info {
		case .success(let info):
			storefrontContents(for: info)
				.foregroundColor(entry.configuration.accentColor.color)
		case .failure(let error):
			Text(error.localizedDescription)
				.foregroundColor(.secondary)
				.padding()
		}
	}
	
	@ViewBuilder
	func storefrontContents(for info: StorefrontInfo) -> some View {
		if widgetFamily == .systemSmall {
			VStack(spacing: 0) {
				if entry.configuration.showRefreshTime == 1 {
					nextRefreshLabel(target: info.nextRefresh)
						.padding(4)
						.frame(maxWidth: .infinity)
						.background {
							Rectangle().opacity(opacities.last!)
						}
				}
				
				storeGrid(for: info)
			}
		} else {
			storeGrid(for: info)
				.overlay(alignment: .top) {
					if entry.configuration.showRefreshTime == 1 {
						ZStack {
							ForEach(0..<3) { _ in // harder soft light lmao, this just looks best
								nextRefreshLabel(target: info.nextRefresh)
									.blendMode(.softLight)
							}
						}
						.background(Capsule().fill(.regularMaterial).padding(-2))
						.padding(6)
						.foregroundColor(.primary)
					}
				}
		}
	}
	
	@ViewBuilder
	func storeGrid(for info: StorefrontInfo) -> some View {
		let columnCount = widgetFamily == .systemMedium ? 2 : 1
		let isSmall = widgetFamily == .systemSmall
		
		FixedColumnGrid(columns: columnCount) {
			ForEach(info.skins.indexed(), id: \.index) { index, skin in
				VStack(spacing: 4) {
					if !isSmall {
						skin.icon?.resizable().aspectRatio(contentMode: .fit)
							.frame(maxWidth: .infinity, maxHeight: .infinity)
					}
					
					Text(skin.name)
						.font(.caption2)
						.opacity(0.8)
						.fixedSize(horizontal: false, vertical: true)
						.lineLimit(isSmall ? 2 : 1)
						.multilineTextAlignment(.center)
				}
				.frame(maxWidth: .infinity, maxHeight: .infinity)
				.padding(.vertical, isSmall ? 4 : 8)
				.padding(.horizontal, 8)
				.background {
					let row = index / columnCount
					let col = index % columnCount
					Rectangle()
						.opacity(opacities[(row + col) % opacities.count])
				}
			}
		}
	}
	
	func nextRefreshLabel(target: Date) -> some View {
		HStack(spacing: 4) {
			Image(systemName: "clock")
			
			if target > .now {
				Text("Refreshes at \(target, format: .dateTime.hour().minute())")
			} else {
				Text("Storefront outdated!")
					.foregroundColor(.red)
			}
		}
		.padding(.trailing, 2)
		.font(.caption.weight(.medium))
	}
}

struct FixedColumnGrid: Layout {
	var columns: Int
	
	func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
		proposal.replacingUnspecifiedDimensions()
	}
	
	func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
		let size = bounds.size / CGSize(
			width: CGFloat(columns),
			height: (CGFloat(subviews.count) / CGFloat(columns)).rounded(.up)
		)
		for (index, view) in subviews.enumerated() {
			let position = CGPoint(x: index % columns, y: index / columns)
			view.place(
				at: bounds.origin + CGVector(size * position),
				proposal: .init(size)
			)
		}
	}
}

struct Widgets_Previews: PreviewProvider {
	static var previews: some View {
		Group {
			let view = StoreEntryView(entry: .init(
				date: .now,
				info: .success(.init(
					nextRefresh: .init(timeIntervalSinceNow: 12345),
					skins: [
						.init(name: "a long-ass testing name (yes)", icon: Image("Example Skin")),
						.init(name: "much longer skin name", icon: Image("Example Skin")),
						.init(name: "test", icon: Image("Example Skin")),
						.init(name: "BlastX Polymer KnifeTech Coated Knife", icon: Image("Example Skin")),
					]
				)),
				configuration: .init() <- {
					$0.accentColor = .unknown
				}
			))
			
			view.previewContext(WidgetPreviewContext(family: .systemSmall))
				.previewDisplayName("Small")
			view.previewContext(WidgetPreviewContext(family: .systemMedium))
				.previewDisplayName("Medium")
			view.previewContext(WidgetPreviewContext(family: .systemLarge))
				.previewDisplayName("Large")
			
			StoreEntryView(entry: .init(
				date: .now,
				info: .failure(Provider.UpdateError.noAccountFound),
				configuration: .init()
			))
			.previewDisplayName("No Account")
			
			StoreEntryView(entry: .init(
				date: .now,
				info: .failure(APIError.rateLimited(retryAfter: 5)),
				configuration: .init()
			))
			.previewDisplayName("Other Error")
		}
		.previewContext(WidgetPreviewContext(family: .systemMedium))
	}
}
