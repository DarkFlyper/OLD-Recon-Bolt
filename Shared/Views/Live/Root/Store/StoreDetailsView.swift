import SwiftUI
import ValorantAPI

struct StoreDetailsView: View {
	var updateTime: Date
	var offers: [StoreOffer.ID: StoreOffer]
	var storefront: Storefront
	var wallet: StoreWallet
	
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
				HStack {
					Text("Night Market")
						.font(.headline)
					
					Spacer()
					
					remainingTimeLabel(nightMarket.remainingDuration)
				}
				
				nightMarketView(for: nightMarket)
				
				Divider()
			}
			
			HStack {
				Text("Daily Offers")
					.font(.headline)
				
				Spacer()
				
				remainingTimeLabel(storefront.skinsPanelLayout.remainingDuration)
			}
			
			ForEach(storefront.skinsPanelLayout.singleItemOffers, id: \.self) { offerID in
				let offer = offers[offerID]!
				OfferCell(offer: offer)
					.background(Color.tertiaryGroupedBackground)
					.cornerRadius(8)
			}
		}
		.padding()
		
		Divider()
		
		HStack(spacing: 20) {
			Text("Available:")
			
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
				Text("<Unknown Bundle>")
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
						Text("-\(offer.discountPercent)%")
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
	@State var chromaOffset = 0
	
	@Environment(\.assets) private var assets
	
	var body: some View {
		let reward = offer.rewards.first!
		let resolved = assets?.resolveSkin(.init(rawID: reward.itemID))
		VStack {
			let chroma = (resolved?.skin.chromas).map { chromas in
				chromas[chromaOffset % chromas.count]
			}
			(chroma?.displayIcon ?? resolved?.displayIcon)?.view()
				.frame(height: 60)
			
			HStack(alignment: .lastTextBaseline) {
				Text((resolved?.skin.displayName ?? "<Unknown Skin>"))
					.fontWeight(.medium)
					.fixedSize(horizontal: false, vertical: true)
				
				Spacer()
				
				CurrencyLabel.multiple(for: offer.cost)
			}
		}
		.padding(12)
		.onTapGesture {
			chromaOffset += 1 // cycle through chromas if available
		}
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
