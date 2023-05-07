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
				itemView(for: item)
			}
			.frame(maxWidth: .infinity)
			.aligningListRowSeparator()
		}
	}
	
	@ViewBuilder
	func itemView(for item: StoreBundle.Item) -> some View {
		let priceLabel = CurrencyLabel(amount: item.basePrice, currencyID: item.currencyID)
			.foregroundStyle(.secondary)
		
		if let skinLevel = item.info.skinLevel {
			let resolved = assets?.resolveSkin(skinLevel)
			NavigationLink {
				if let resolved {
					SkinDetailsView(skin: resolved.skin)
				}
			} label: {
				VStack {
					resolved?.displayIcon?.view()
						.frame(height: 60)
					HStack {
						(resolved?.skin).label()
							.frame(maxWidth: .infinity, alignment: .leading)
						Spacer()
						priceLabel
					}
				}
				.padding(.vertical, 8)
			}
		} else if let buddy = item.info.buddy {
			let info = assets?.resolveBuddy(buddy)
			NavigationButton {
				fullscreenImages = info.map { [$0.displayIcon] }
			} label: {
				info?.displayIcon.view()
					.frame(height: 60)
				info.label()
				Spacer()
				priceLabel
			}
		} else if let card = item.info.card {
			let info = assets?.playerCards[card]
			NavigationButton {
				fullscreenImages = info.map { [$0.largeArt, $0.wideArt, $0.smallArt] }
			} label: {
				info?.smallArt.view()
					.frame(height: 60)
				info.label()
				Spacer()
				priceLabel
			}
		} else if let title = item.info.title {
			HStack {
				PlayerTitleLabel(titleID: title)
				Spacer()
				priceLabel
			}
		} else if let spray = item.info.spray {
			let info = assets?.sprays[spray]
			NavigationButton {
				fullscreenImages = info.map { [$0.fullIcon, $0.displayIcon] }
			} label: {
				info?.bestIcon.view()
					.frame(height: 60)
				info.label()
				Spacer()
				priceLabel
			}
		} else {
			Text("Unknown item of type \(item.info.itemTypeID.description)", comment: "Store Bundle Details: should never show, but if Riot adds a new kind of item to a bundle, this would show")
				.foregroundStyle(.secondary)
				.multilineTextAlignment(.center)
		}
	}
}

extension PlayerCardInfo? {
	func label() -> some View {
		UnwrappingView(
			value: self?.displayName,
			placeholder: Text("Unknown Card", comment: "placeholder")
		)
	}
}

extension SprayInfo? {
	func label() -> some View {
		UnwrappingView(
			value: self?.displayName,
			placeholder: Text("Unknown Spray", comment: "placeholder")
		)
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
