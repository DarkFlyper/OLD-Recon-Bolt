import SwiftUI
import ValorantAPI
import RegexBuilder

struct SearchableAssetPicker<Item: SearchableAsset, RowContent: View, Deselector: View>: View {
	var allItems: [Item.ID: Item]
	var ownedItems: Set<Item.ID>
	@ViewBuilder var rowContent: (Item) -> RowContent
	@ViewBuilder var deselector: () -> Deselector
	
	@State private var search = ""
	
	var body: some View {
		let results = ownedItems
			.lazy
			.compactMap { allItems[$0] }
			.filter { searchAccepts($0.searchableText) }
			.sorted(on: \.sortValue)
		
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
					Text("\(ownedItems.count)/\(allItems.count) owned", comment: "Loadout Item Picker: number of items owned out of all such items in the game")
					let missing = ownedItems.lazy.filter { allItems[$0] == nil }.count
					if missing > 0 {
						Text("\(missing) hidden due to outdated assets", comment: "Loadout Item Picker: number of hidden items—this should never show nowadays")
					}
				}
			}
		}
		.searchable(text: $search)
	}
	
	func searchAccepts(_ candidate: String) -> Bool {
		if #available(iOS 16.1, *) { // due to a bug from apple, this crashes in 16.0
			return candidate.firstMatch(of: Regex {
				Anchor.wordBoundary
				search
			}.ignoresCase()) != nil
		} else {
			return candidate.lowercased().starts(with: search.lowercased()) // basic fallback
		}
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
	associatedtype SortValue: Comparable
	
	var searchableText: String { get }
	var sortValue: SortValue { get }
}

extension SearchableAsset where SortValue == String {
	var sortValue: SortValue { searchableText }
}

protocol SimpleSearchableAsset: SearchableAsset {
	static var assetPath: KeyPath<AssetCollection, [ID: Self]> { get }
	static var inventoryPath: KeyPath<Inventory, Set<ID>> { get }
	static var defaultItems: [ID] { get }
}

extension SimpleSearchableAsset {
	static var defaultItems: [ID] { [] }
}
