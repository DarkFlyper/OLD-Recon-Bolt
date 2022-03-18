import SwiftUI
import ValorantAPI

struct StoreDetailsView: View {
	var updateTime: Date
	var offers: [StoreOffer.ID: StoreOffer]
	var storefront: Storefront
	
	@Environment(\.assets) private var assets
	@ScaledMetric(relativeTo: .body) private var currencyIconSize = 20.0
	
	var body: some View {
		Divider()
		
		VStack(spacing: 16) {
			ForEach(storefront.featuredBundle.bundles) { bundle in
				bundleCell(for: bundle)
					.background(Color.tertiaryGroupedBackground)
					.cornerRadius(8)
			}
			
			Divider()
			
			HStack {
				Text("Daily Offers")
					.font(.headline)
				
				Spacer()
				
				remainingTimeLabel(storefront.skinsPanelLayout.remainingDuration)
			}
			
			ForEach(storefront.skinsPanelLayout.singleItemOffers, id: \.self) { offerID in
				let offer = offers[offerID]!
				offerCell(for: offer)
					.background(Color.tertiaryGroupedBackground)
					.cornerRadius(8)
			}
		}
		.padding()
	}
	
	@ViewBuilder
	func bundleCell(for bundle: StoreBundle) -> some View {
		VStack(spacing: 0) {
			if let info = assets?.bundles[bundle.assetID] {
				info.displayIcon.asyncImage()
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
	
	@ViewBuilder
	func offerCell(for offer: StoreOffer) -> some View {
		let reward = offer.rewards.first!
		let path = assets?.skinsByLevelID[.init(rawID: reward.itemID)]
		let skin = path.map { assets!.weapons[$0.weapon]!.skins[$0.skinIndex] }
		VStack {
			skin?.displayIcon?.asyncImage()
				.frame(height: 60)
			
			HStack {
				Text(skin?.displayName ?? "<Unknown Skin>")
					.fontWeight(.medium)
				Spacer()
				ForEach(offer.cost.sorted(on: \.key.description), id: \.key) { currencyID, amount in
					Text("\(amount)")
					let currency = assets?.currencies[currencyID]
					currency?.displayIcon.imageOrPlaceholder(renderingMode: .template)
						.frame(width: currencyIconSize, height: currencyIconSize)
				}
			}
		}
		.padding(12)
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

#if DEBUG
struct StoreDetailsView_Previews: PreviewProvider {
	static var previews: some View {
		RefreshableBox(title: "Store", refreshAction: {}) {
			StoreDetailsView(
				updateTime: .now,
				offers: .init(values: PreviewData.storeOffers),
				storefront: PreviewData.storefront
			)
		}
		.forPreviews()
		.withToolbar()
		.inEachColorScheme()
	}
}
#endif
