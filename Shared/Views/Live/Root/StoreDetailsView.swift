import SwiftUI
import ValorantAPI

struct StoreDetailsView: View {
	var offers: [StoreOffer.ID: StoreOffer]
	var storefront: Storefront
	
	@Environment(\.assets) private var assets
	@ScaledMetric(relativeTo: .body) private var currencyIconSize = 20.0
	
	var body: some View {
		Divider()
		
		VStack(spacing: 16) {
			ForEach(storefront.skinsPanelLayout.singleItemOffers, id: \.self) { offerID in
				let offer = offers[offerID]!
				offerCell(for: offer)
					.background(Color(.tertiarySystemGroupedBackground))
					.cornerRadius(8)
			}
		}
		.padding()
	}
	
	@ViewBuilder
	func offerCell(for offer: StoreOffer) -> some View {
		let reward = offer.rewards.first!
		let path = assets?.skinsByLevelID[.init(rawID: reward.itemID)]
		let skin = path.map { assets!.weapons[$0.weapon]!.skins[$0.skinIndex] }
		VStack {
			skin?.displayIcon?.asyncImage()
				.frame(maxWidth: .infinity, idealHeight: 80)
			
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
		.padding()
	}
}

#if DEBUG
struct StoreDetailsView_Previews: PreviewProvider {
	static var previews: some View {
		RefreshableBox(title: "Store", refreshAction: {}) {
			StoreDetailsView(
				offers: .init(values: PreviewData.storeOffers),
				storefront: PreviewData.storefront
			)
		}
		.forPreviews()
		.inEachColorScheme()
	}
}
#endif
