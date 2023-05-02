import SwiftUI
import ValorantAPI

struct BundleDetailsView: View {
	var bundle: StoreBundle
	
	@Environment(\.assets) private var assets
	
	var body: some View {
		if let info = assets?.bundles[bundle.assetID] {
			List {
				contents(for: info)
			}
			.background(Color.groupedBackground)
			.navigationTitle(info.displayName)
		} else {
			VStack(spacing: 8) {
				Text("Unknown bundle!")
				Text("Are your assets outdated?")
			}
			.foregroundColor(.secondary)
			.padding()
		}
	}
	
	@ViewBuilder
	func contents(for info: StoreBundleInfo) -> some View {
		Section {
			info.displayIcon.view()
				.listRowInsets(.init())
				.aligningListRowSeparator()
			
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
			HStack {
				let info = assets?.resolveBuddy(buddy)
				info?.displayIcon.view()
					.frame(height: 60)
				info.label()
				Spacer()
				priceLabel
			}
		} else if let card = item.info.card {
			HStack {
				let info = assets?.playerCards[card]
				info?.smallArt.view()
					.frame(height: 60)
				info.label()
				Spacer()
				priceLabel
				// TODO: way to see more icon variants?
			}
		} else if let title = item.info.title {
			HStack {
				PlayerTitleLabel(titleID: title)
				Spacer()
				priceLabel
			}
		} else if let spray = item.info.spray {
			HStack {
				let info = assets?.sprays[spray]
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
