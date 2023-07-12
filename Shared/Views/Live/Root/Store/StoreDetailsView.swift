import SwiftUI
import ValorantAPI

struct StoreDetailsView: View {
	var updateTime: Date
	var storefront: Storefront
	var wallet: StoreWallet
	
	@State var isNightMarketExpanded = false
	
	@Environment(\.assets) private var assets
	
	private static let currencies: [Currency.ID] = [.valorantPoints, .radianitePoints, .kingdomCredits]
	
	var body: some View {
		VStack(spacing: 16) {
			ForEach(storefront.featuredBundle.bundles) { bundle in
				NavigationLink {
					BundleDetailsView(bundle: bundle)
				} label: {
					bundleCell(for: bundle)
						.background(Color.tertiaryGroupedBackground)
						.cornerRadius(8)
						.tint(.primary)
				}
			}
			
			if let offers = storefront.accessoryStore.offers {
				NavigationLink {
					AccessoryStoreView(
						accessoryStore: storefront.accessoryStore
					) {
						HStack {
							remainingTimeLabel(storefront.accessoryStore.remainingDuration)
								.foregroundColor(.primary) // secondary relative to this
							Spacer()
							CurrencyLabel(amount: wallet[.kingdomCredits], currencyID: .kingdomCredits)
						}
					}
				} label: {
					accessoryStoreCell(offers: offers)
						.background(Color.tertiaryGroupedBackground)
						.cornerRadius(8)
						.tint(.primary)
				}
			}
			
			Divider()
			
			if let nightMarket = storefront.nightMarket {
				ExpandButton(isExpanded: $isNightMarketExpanded) {
					Text("Night Market", comment: "Store")
						.font(.headline)
					
					Spacer()
					
					remainingTimeLabel(nightMarket.remainingDuration)
				}
				
				if isNightMarketExpanded {
					nightMarketView(for: nightMarket)
				}
				
				Divider()
			}
			
			HStack {
				Text("Daily Offers", comment: "Store")
					.font(.headline)
				
				Spacer()
				
				remainingTimeLabel(storefront.dailySkinStore.remainingDuration)
			}
			
			ForEach(storefront.dailySkinStore.offers) { offer in
				OfferCell(offer: offer)
			}
			.cornerRadius(8)
		}
		.padding()
		
		Divider()
		
		HStack(spacing: 20) {
			Image(systemName: "briefcase")
				.foregroundStyle(.secondary)
			
			Spacer(minLength: 0)
			
			ForEach(Self.currencies, id: \.self) { currency in
				CurrencyLabel(amount: wallet[currency], currencyID: currency)
			}
		}
		.minimumScaleFactor(0.5)
		.lineLimit(1)
		.padding()
	}
	
	@ViewBuilder
	func bundleCell(for bundle: StoreBundle) -> some View {
		VStack(spacing: 0) {
			if let info = assets?.bundles[bundle.assetID] {
				info.displayIcon.view()
					.aspectRatio(1648/804, contentMode: .fill)
				
				HStack {
					Text(info.displayName)
						.fontWeight(.medium)
						.multilineTextAlignment(.leading)
					
					Spacer()
					
					remainingTimeLabel(bundle.remainingDuration)
					
					Image(systemName: "chevron.forward")
						.foregroundStyle(.secondary)
						.imageScale(.small)
				}
				.padding(12)
			} else {
				Text("Unknown Bundle", comment: "placeholder")
					.padding(12)
			}
		}
	}
	
	@ScaledMetric private var priceLabelOffset = 16
	
	func nightMarketView(for market: Storefront.NightMarket) -> some View {
		ForEach(market.offers) { offer in
			OfferCell(offer: offer.offer)
				.overlay(alignment: .bottomTrailing) {
					VStack {
						CurrencyLabel.multiple(for: offer.discountedCosts)
						Text("-\(offer.discountPercent)%", comment: "Store: night market discount")
							.font(.footnote.bold())
							.foregroundColor(.accentColor)
					}
					.padding(8)
					.frame(width: 12 * priceLabelOffset) // make sure edges aren't visibleπ
					.background(Material.ultraThin)
					.frame(width: 0)
					.offset(y: -priceLabelOffset)
					.rotationEffect(.degrees(-45), anchor: .bottom)
				}
				.background(Color.tertiaryGroupedBackground)
				.cornerRadius(8)
		}
	}
	
	func remainingTimeLabel(_ seconds: TimeInterval) -> some View {
		HStack(spacing: 4) {
			CountdownText(target: updateTime + seconds)
			
			Image(systemName: "clock")
		}
		.font(.caption.weight(.medium))
		.foregroundStyle(.secondary)
	}
	
	func accessoryStoreCell(offers: [Storefront.AccessoryStore.Offer]) -> some View {
		VStack(spacing: 12) {
			HStack {
				ForEach(offers, id: \.offer.id) { offer in
					icon(for: offer.offer.rewards.first!)
						.frame(width: 60, height: 60)
				}
			}
			
			Divider()
			
			HStack {
				Text("Accessories", comment: "Store: accessory section")
				
				Spacer()
				
				remainingTimeLabel(storefront.accessoryStore.remainingDuration)
				Image(systemName: "chevron.right")
					.foregroundStyle(.secondary)
			}
		}
		.font(.body.weight(.medium))
		.imageScale(.small)
		.padding(12)
	}
	
	@ViewBuilder
	func icon(for reward: StoreOffer.Reward) -> some View {
		switch reward.itemTypeID {
		case .buddies:
			(assets?.resolveBuddy(.init(rawID: reward.itemID))?.displayIcon).view()
		case .sprays:
			(assets?.sprays[.init(rawID: reward.itemID)]?.bestIcon).view()
		case .cards:
			(assets?.playerCards[.init(rawID: reward.itemID)]?.smallArt).view()
				.cornerRadius(8)
		case .titles:
			Image("Player Title")
				.resizable()
				.foregroundStyle(.secondary)
		default:
			EmptyView()
		}
	}
}

struct OfferCell: View {
	var offer: StoreOffer
	
	@Environment(\.assets) private var assets
	@Environment(\.colorScheme) private var colorScheme
	
	var body: some View {
		let reward = offer.rewards.first!
		let resolved = assets?.resolveSkin(.init(rawID: reward.itemID))
		let tier = resolved?.skin.contentTierID.flatMap { assets?.contentTiers[$0] }
		
		NavigationLink {
			if let resolved {
				SkinDetailsView(skin: resolved.skin)
			}
		} label: {
			VStack {
				let chroma = resolved?.skin.chromas.first
				(chroma?.fullRender ?? chroma?.displayIcon ?? resolved?.displayIcon)?.view()
					.frame(height: 60)
				
				HStack(alignment: .lastTextBaseline) {
					(resolved?.skin).label()
						.font(.body.weight(.medium))
						.multilineTextAlignment(.leading)
						.fixedSize(horizontal: false, vertical: true)
					
					Spacer()
					
					CurrencyLabel.multiple(for: offer.cost)
				}
			}
			.overlay(alignment: .topLeading) {
				tier?.displayIcon.view()
					.frame(width: 20)
			}
			.overlay(alignment: .topTrailing) {
				if resolved != nil {
					Image(systemName: "chevron.forward")
						.font(.body.weight(.medium))
						.imageScale(.small)
				}
			}
			.padding(12)
			.foregroundColor(tier?.color?.opaque(), adjustedFor: colorScheme)
			.background(tier?.color?.opaque().opacity(0.2))
		}
		.disabled(resolved == nil)
	}
}

struct AccessoryStoreView<Footer: View>: View {
	var accessoryStore: Storefront.AccessoryStore
	@ViewBuilder var footer: Footer
	@State var fullscreenImages: AssetImageCollection?
	
	@Environment(\.assets) private var assets
	
	var body: some View {
		List {
			Section {
				ForEach(accessoryStore.offers ?? [], id: \.offer.id, content: row(for:))
			} footer: {
				footer
			}
		}
		.navigationTitle(Text("Accessory Store", comment: "Store: Accessory List: title"))
		.lightbox(for: $fullscreenImages)
	}
	
	@ViewBuilder
	func row(for accessoryOffer: Storefront.AccessoryStore.Offer) -> some View {
		let offer = accessoryOffer.offer
		StoreItemView(item: offer.rewards.first!, fullscreenImages: $fullscreenImages) {
			let (currency, amount) = offer.cost.first!
			CurrencyLabel(amount: amount, currencyID: currency)
		}
	}
}

extension WeaponSkin? {
	func label() -> some View {
		UnwrappingView(
			value: self?.displayName,
			placeholder: Text("Unknown Skin", comment: "placeholder")
		)
	}
}

struct CurrencyLabel: View {
	var amount: Int
	var currencyID: Currency.ID
	
	@Environment(\.assets) private var assets
	@ScaledMetric(relativeTo: .body) private var iconSize = 20.0
	
	var body: some View {
		HStack {
			Text("\(amount)")
			let currency = assets?.currencies[currencyID]
			currency?.displayIcon.view(renderingMode: .template)
				.frame(width: iconSize, height: iconSize)
		}
	}
	
	static func multiple(for costs: [Currency.ID: Int]) -> some View {
		ForEach(costs.sorted(on: \.key.description), id: \.key) { currencyID, amount in
			CurrencyLabel(amount: amount, currencyID: currencyID)
				.layoutPriority(1)
		}
	}
}

#if DEBUG
struct StoreDetailsView_Previews: PreviewProvider {
	static var previews: some View {
		ScrollView {
			RefreshableBox(title: "Store", isExpanded: .constant(true)) {
				StoreDetailsView(
					updateTime: .now,
					storefront: PreviewData.storefront,
					wallet: PreviewData.storeWallet
				)
			} refresh: { _ in }
				.forPreviews()
		}
		.withToolbar()
	}
}
#endif
