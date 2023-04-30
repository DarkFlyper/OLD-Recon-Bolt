import SwiftUI
import ValorantAPI

struct StoreDetailsView: View {
	var updateTime: Date
	var offers: [StoreOffer.ID: StoreOffer]
	var storefront: Storefront
	var wallet: StoreWallet
	
	@State var isNightMarketExpanded = false
	
	@Environment(\.assets) private var assets
	
	private static let currencies: [Currency.ID] = [.valorantPoints, .radianitePoints]
	
	var body: some View {
		Divider()
		
		VStack(spacing: 16) {
			ForEach(storefront.featuredBundle.bundles) { bundle in
				bundleCell(for: bundle)
					.background(Color.tertiaryGroupedBackground)
					.cornerRadius(8)
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
				
				remainingTimeLabel(storefront.skinsPanelLayout.remainingDuration)
			}
			
			ForEach(storefront.skinsPanelLayout.singleItemOffers, id: \.self) { offerID in
				if let offer = offers[offerID] {
					OfferCell(offer: offer)
				} else {
					Text("Unknown Offer", comment: "Store")
						.foregroundStyle(.secondary)
						.padding()
						.frame(maxWidth: .infinity)
						.background(Color.tertiaryGroupedBackground)
				}
			}
			.cornerRadius(8)
		}
		.padding()
		
		Divider()
		
		HStack(spacing: 20) {
			Text("Available:", comment: "Store: available currency")
			
			Spacer()
			
			ForEach(Self.currencies, id: \.self) { currency in
				CurrencyLabel(amount: wallet[currency], currencyID: currency)
			}
		}
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
					
					Spacer()
					
					remainingTimeLabel(bundle.remainingDuration)
				}
				.padding(12)
			} else {
				Text("Unknown Bundle", comment: "placeholder")
					.padding(12)
			}
		}
	}
	
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
					.frame(width: 256)
					.background(Material.ultraThin)
					.frame(width: 0)
					.offset(y: -16)
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
					UnwrappingView(
						value: resolved?.skin.displayName,
						placeholder: Text("Unknown Skin", comment: "placeholder")
					)
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
				}
			}
			.padding(12)
			.foregroundColor(tier?.color?.opacity(10), adjustedFor: colorScheme)
			.background(tier?.color?.opacity(1.5))
		}
		.disabled(resolved == nil)
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
					offers: .init(values: PreviewData.storeOffers),
					storefront: PreviewData.storefront,
					wallet: PreviewData.storeWallet
				)
			} refresh: { _ in }
				.forPreviews()
		}
	}
}
#endif
