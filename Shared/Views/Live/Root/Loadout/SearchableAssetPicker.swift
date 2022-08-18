import SwiftUI
import ValorantAPI

struct SearchableAssetPicker<Item: SearchableAsset, RowContent: View, Deselector: View>: View {
	var allItems: [Item.ID: Item]
	var ownedItems: Set<Item.ID>
	@ViewBuilder var rowContent: (Item) -> RowContent
	@ViewBuilder var deselector: () -> Deselector
	
	@State private var search = ""
	
	var body: some View {
		let lowerSearch = search.lowercased()
		let results = ownedItems
			.lazy
			.compactMap { allItems[$0] }
			.filter {
				$0.searchableText
					.lowercased()
					.split(separator: " ", omittingEmptySubsequences: false) // important for default title = " "
					.contains { $0.hasPrefix(lowerSearch) }
			}
			.sorted(on: \.searchableText)
		
		List {
			if search.isEmpty, Deselector.self != EmptyView.self {
				Section {
					deselector()
				}
			}
			
			Section {
				ForEach(results) { item in
					rowContent(item)
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
}

struct SelectableRow<Content: View>: View {
	var isSelected: Bool
	var select: () -> Void
	@ViewBuilder var content: () -> Content
	
	var body: some View {
		Button(action: select) {
			HStack {
				content()
					.foregroundColor(.primary)
				Spacer()
				Image(systemName: "checkmark")
					.opacity(isSelected ? 1 : 0)
			}
		}
	}
}

extension SelectableRow {
	init<Item: Equatable>(
		selection: Binding<Item>,
		item: Item,
		@ViewBuilder content: @escaping () -> Content
	) {
		self.init(
			isSelected: selection.wrappedValue == item,
			select: { selection.wrappedValue = item },
			content: content
		)
	}
}

struct SimpleSearchableAssetPicker<Item: SimpleSearchableAsset, RowContent: View>: View {
	var inventory: Inventory
	@ViewBuilder var rowContent: (Item) -> RowContent
	
	var body: some View {
		AssetsUnwrappingView { assets in
			SearchableAssetPicker(
				allItems: assets[keyPath: Item.assetPath],
				ownedItems: inventory[keyPath: Item.inventoryPath].union(Item.defaultItems)
			) { item in
				rowContent(item)
			} deselector: {}
		}
	}
}

protocol SearchableAsset: Identifiable {
	var searchableText: String { get }
}

protocol SimpleSearchableAsset: SearchableAsset {
	static var assetPath: KeyPath<AssetCollection, [ID: Self]> { get }
	static var inventoryPath: KeyPath<Inventory, Set<ID>> { get }
	static var defaultItems: [ID] { get }
}

extension SimpleSearchableAsset {
	static var defaultItems: [ID] { [] }
}
