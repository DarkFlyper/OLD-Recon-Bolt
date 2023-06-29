import SwiftUI
import ValorantAPI

struct StoreItemView<Item: UntypedStoreItem, PriceLabel: View>: View {
	var item: Item
	@Binding var fullscreenImages: AssetImageCollection?
	
	@ViewBuilder var priceLabel: PriceLabel
	
	@Environment(\.assets) private var assets
	
	var body: some View {
		contents()
			.frame(maxWidth: .infinity)
			.aligningListRowSeparator()
	}
	
	@ViewBuilder
	func contents() -> some View {
		let iconSize = 60.0
		
		if let skinLevel = item.skinLevel {
			let resolved = assets?.resolveSkin(skinLevel)
			NavigationLink {
				if let resolved {
					SkinDetailsView(skin: resolved.skin)
				}
			} label: {
				VStack {
					resolved?.displayIcon?.view()
						.frame(height: iconSize)
					HStack {
						(resolved?.skin).label()
							.frame(maxWidth: .infinity, alignment: .leading)
						Spacer()
						priceLabel
					}
				}
				.padding(.vertical, 8)
			}
		} else if let buddy = item.buddy {
			let info = assets?.resolveBuddy(buddy)
			NavigationButton {
				fullscreenImages = info.map { [$0.displayIcon] }
			} label: {
				HStack(spacing: 12) {
					info?.displayIcon.view()
						.frame(width: iconSize, height: iconSize)
					info.label()
					Spacer()
					priceLabel
				}
			}
		} else if let card = item.card {
			let info = assets?.playerCards[card]
			NavigationButton {
				fullscreenImages = info.map { [$0.largeArt, $0.wideArt, $0.smallArt] }
			} label: {
				HStack(spacing: 12) {
					info?.smallArt.view()
						.frame(width: iconSize, height: iconSize)
					info.label()
					Spacer()
					priceLabel
				}
			}
		} else if let title = item.title {
			HStack {
				HStack(spacing: 12) {
					Image("Player Title")
						.resizable()
						.foregroundStyle(.secondary)
						.frame(width: iconSize, height: iconSize)
					PlayerTitleLabel(titleID: title)
					Spacer()
					priceLabel
				}
			}
		} else if let spray = item.spray {
			let info = assets?.sprays[spray]
			NavigationButton {
				fullscreenImages = info.map { [$0.fullIcon, $0.displayIcon] }
			} label: {
				HStack(spacing: 12) {
					info?.bestIcon.view()
						.frame(width: iconSize, height: iconSize)
					info.label()
					Spacer()
					priceLabel
				}
			}
		} else {
			Text("Unknown item of type \(item.itemTypeID.description)", comment: "Store Bundle Details: should never show, but if Riot adds a new kind of item to a bundle, this would show")
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
