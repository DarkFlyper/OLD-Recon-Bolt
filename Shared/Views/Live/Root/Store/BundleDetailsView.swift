import SwiftUI
import ValorantAPI

struct BundleDetailsView: View {
	var bundle: StoreBundle
	
	@State var fullscreenImages: AssetImageCollection?
	
	@Environment(\.assets) private var assets
	
	var body: some View {
		if let info = assets?.bundles[bundle.assetID] {
			List {
				contents(for: info)
			}
			.navigationTitle(info.displayName)
			.lightbox(for: $fullscreenImages)
		} else {
			VStack(spacing: 8) {
				Text("Unknown bundle!")
				Text("Are your assets outdated?")
			}
			.foregroundColor(.secondary)
			.padding()
		}
	}
	
	@ScaledMetric private var priceLabelOffset = 48
	
	@ViewBuilder
	func contents(for info: StoreBundleInfo) -> some View {
		Section {
			info.displayIcon.view()
				.listRowInsets(.init())
				.aligningListRowSeparator()
				.overlay(alignment: .bottomTrailing) {
					let totalCost = bundle.items.lazy.map(\.discountedPrice).reduce(0, +)
					CurrencyLabel(amount: totalCost, currencyID: bundle.currencyID)
						.padding(8)
						.frame(width: priceLabelOffset * 4) // gotta make sure the corners aren't visible
						.background(Material.ultraThin)
						.frame(width: 0)
						.offset(y: -priceLabelOffset)
						.rotationEffect(.degrees(-45), anchor: .bottom)
				}
				.onTapGesture { fullscreenImages = [info.displayIcon] }
			
			if let extraDescription = info.extraDescription {
				Text(extraDescription)
			}
		}
		
		ForEach(bundle.items) { item in
			VStack {
				StoreItemView(item: item.info, fullscreenImages: $fullscreenImages) {
					CurrencyLabel(amount: item.basePrice, currencyID: item.currencyID)
						.foregroundStyle(.secondary)
				}
			}
		}
	}
}

#if DEBUG
struct BundleDetailsView_Previews: PreviewProvider {
	static var previews: some View {
		BundleDetailsView(bundle: PreviewData.storefront.featuredBundle.bundles.first!)
			.withToolbar()
	}
}
#endif
