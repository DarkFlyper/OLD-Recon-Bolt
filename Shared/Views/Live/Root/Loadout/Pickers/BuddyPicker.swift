import SwiftUI
import ValorantAPI

struct BuddyPicker: View {
	var weapon: Weapon.ID
	@Binding var loadout: UpdatableLoadout
	var inventory: Inventory
	
	@State private var isAssigningBuddy = false
	@State private var buddyToAssign: BuddyLevel?
	
	@Environment(\.assets) private var assets
	
	var body: some View {
		buddyList
			.confirmationDialog(
				"Out of instances!",
				isPresented: $isAssigningBuddy,
				titleVisibility: .visible,
				presenting: buddyToAssign
			) { level in
				ForEach((inventory.buddies[level.id] ?? []).indexed(), id: \.element) { index, instance in
					let currentOwner = loadout.currentWeapon(for: instance)!
					Button {
						loadout.guns[currentOwner]!.buddy = nil
						loadout.guns[weapon]!.buddy = level.instance(instance)
					} label: {
						let name = assets?.weapons[currentOwner]?.displayName ?? "unknown gun"
						Text("\(name)")
					}
				}
			} message: { level in
				Text("Choose a weapon to take \(level.buddy.displayName) from.")
			}
			.navigationTitle("Choose Buddy")
	}
	
	var buddyList: some View {
		AssetsUnwrappingView { assets in
			let ownedItems = Set(inventory.buddies.keys)
			let allItems = Dictionary(values: assets.buddies.values.map(BuddyLevel.init))
			
			SearchableAssetPicker(allItems: allItems, ownedItems: ownedItems) { level in
				let instances = inventory.buddies[level.id] ?? []
				let selection = loadout.guns[weapon]?.buddy?.instance
				SelectableRow(isSelected: instances.contains { $0 == selection }) {
					assign(level)
				} content: {
					level.buddy.displayIcon.view()
						.frame(width: 48, height: 48)
					Text(level.buddy.displayName)
				}
			}
		}
	}
	
	func assign(_ level: BuddyLevel) {
		let instances = inventory.buddies[level.id] ?? []
		let unassigned = instances.first { instance in
			return loadout.currentWeapon(for: instance) == nil
		}
		
		if let instance = unassigned {
			loadout.guns[weapon]!.buddy = level.instance(instance)
		} else {
			buddyToAssign = level
			isAssigningBuddy = true
		}
	}
}

extension BuddyLevel: SearchableAsset {
	var searchableText: String { buddy.displayName }
}
