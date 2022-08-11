import SwiftUI
import ValorantAPI

struct LoadoutDetailsView: View {
	var fetchedLoadout: Loadout
	@State private var loadout: UpdatableLoadout
	var inventory: Inventory
	
	@Environment(\.valorantLoad) private var load
	
    var body: some View {
		Divider()
		
		let loadoutBinding = Binding { loadout } set: { newLoadout in
			loadout = newLoadout
			Task {
				await load {
					loadout = .init(try await $0.updateLoadout(to: .init(newLoadout)))
				}
			}
		}
		
		LoadoutCustomizer(inventory: inventory, loadout: loadoutBinding)
			.buttonBorderShape(.capsule)
			.padding(.bottom)
			.task(id: fetchedLoadout.version) {
				loadout = .init(fetchedLoadout)
			}
	}
}

private struct LoadoutCustomizer: View {
	var inventory: Inventory
	@Binding var loadout: UpdatableLoadout
	
	@Environment(\.assets) private var assets
	
	var body: some View {
		VStack(spacing: 16) {
			cardPicker
			
			titlePicker
			
			sprayPicker
			
			NavigationLink {
				WeaponLoadoutView(loadout: $loadout, inventory: inventory)
			} label: {
				HStack {
					Text("Weapon Loadout")
					Image(systemName: "chevron.right")
				}
			}
			.buttonStyle(.bordered)
		}
	}
	
	var cardPicker: some View {
		NavigationLink {
			SimpleSearchableAssetPicker(
				inventory: inventory,
				selected: $loadout.identity.card
			) { (card: PlayerCardInfo) in
				card.smallArt.imageOrPlaceholder()
					.frame(width: 48, height: 48)
				Text(card.displayName)
					.foregroundColor(.primary)
			}
			.navigationTitle("Player Cards")
		} label: {
			PlayerCardImage.wide(loadout.identity.card)
				.overlay(alignment: .bottomTrailing) {
					Image(systemName: "pencil.circle.fill")
						.foregroundStyle(.regularMaterial)
						.font(.system(size: 24))
						.padding(8)
				}
		}
	}
	
	var titlePicker: some View {
		NavigationLink {
			SimpleSearchableAssetPicker(
				inventory: inventory,
				selected: $loadout.identity.title
			) { (title: PlayerTitleInfo) in
				title.textOrBlankDescription
			}
			.navigationTitle("Player Titles")
		} label: {
			HStack {
				if let title = assets?.playerTitles[loadout.identity.title] {
					title.textOrBlankDescription
				} else {
					Text("<unknown title>")
				}
				
				Image(systemName: "pencil.circle.fill")
					.foregroundColor(.secondary)
					.padding(.trailing, -4)
			}
			.foregroundColor(.primary)
		}
		.buttonStyle(.bordered)
	}
	
	var sprayPicker: some View {
		HStack {
			ForEach(Spray.Slot.ID.inOrder, id: \.self) { slot in
				SprayCell(inventory: inventory, slot: slot, spray: $loadout.sprays[slot])
			}
			.frame(maxWidth: 128)
		}
		.padding(.horizontal)
	}
	
	struct SprayCell: View {
		var inventory: Inventory
		var slot: Spray.Slot.ID
		@Binding var spray: Spray.ID?
		
		@Environment(\.assets) private var assets
		
		var body: some View {
			EmptyView()
			NavigationLink {
				SprayPicker(inventory: inventory, selection: $spray)
			} label: {
				VStack {
					if let spray = spray {
						let info = assets?.sprays[spray]
						(info?.bestIcon).asyncImageOrPlaceholder()
							.aspectRatio(1, contentMode: .fit)
					} else {
						Color.clear
					}
					
					Text(slot.name)
						.font(.caption)
						.foregroundColor(.secondary)
				}
			}
			.buttonStyle(.bordered)
			.buttonBorderShape(.roundedRectangle(radius: 8))
		}
	}
}

extension LoadoutDetailsView {
	init(loadout: Loadout, inventory: Inventory) {
		self.init(fetchedLoadout: loadout, loadout: .init(loadout), inventory: inventory)
	}
}

struct SprayPicker: View {
	var inventory: Inventory
	@Binding var selection: Spray.ID?
	@State private var search = ""
	
	var body: some View {
		AssetsUnwrappingView { assets in
			List {
				let ownedItems = inventory.sprays
				let allItems = assets.sprays
				
				let lowerSearch = search.lowercased()
				let results = ownedItems
					.lazy
					.compactMap { assets.sprays[$0] }
					.filter { $0.searchableText.lowercased().hasPrefix(lowerSearch) }
					.sorted(on: \.searchableText)
				
				Section {
					ForEach(results) { spray in
						SelectableRow(selection: $selection, item: spray.id) {
							spray.bestIcon.asyncImage()
								.frame(width: 48, height: 48)
							Text(spray.displayName)
						}
					}
				} footer: {
					VStack(alignment: .leading) {
						Text("\(ownedItems.count)/\(allItems.count) owned")
						let missing = ownedItems.lazy.filter { allItems[$0] == nil }.count
						if missing > 0 {
							Text("\(missing) hidden due to outdated assets")
						}
					}
				}
			}
			.searchable(text: $search)
		}
		.navigationTitle("Choose Spray")
	}
}

extension PlayerTitleInfo {
	@ViewBuilder
	var textOrBlankDescription: some View {
		if let titleText = titleText {
			Text(titleText)
		} else {
			Text("No Title")
				.foregroundColor(.secondary)
		}
	}
}

extension PlayerCardInfo: SimpleSearchableAsset {
	static let assetPath = \AssetCollection.playerCards
	static let inventoryPath = \Inventory.cards
	
	var searchableText: String { displayName }
}

extension PlayerTitleInfo: SimpleSearchableAsset {
	static let assetPath = \AssetCollection.playerTitles
	static let inventoryPath = \Inventory.titles
	
	var searchableText: String { displayName }
}

extension SprayInfo: SimpleSearchableAsset {
	static let assetPath = \AssetCollection.sprays
	static let inventoryPath = \Inventory.sprays
	
	var searchableText: String { displayName }
}

#if DEBUG
struct LoadoutDetailsView_Previews: PreviewProvider {
	static var previews: some View {
		RefreshableBox(title: "Loadout") {
			LoadoutDetailsView(
				loadout: PreviewData.loadout,
				inventory: PreviewData.inventory
			)
		} refresh: { _ in }
			.forPreviews()
			.navigationTitle("Loadout")
			.withToolbar()
	}
}
#endif
