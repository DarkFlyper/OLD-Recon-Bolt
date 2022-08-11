import SwiftUI
import ValorantAPI

struct GunCustomizer: View {
	@Binding var gun: Loadout.Gun
	@Binding var loadout: UpdatableLoadout
	var resolved: ResolvedLevel
	var inventory: Inventory
	
	@Environment(\.assets) private var assets
	
	var body: some View {
		List {
			Section(resolved.skin.displayName) {
				Group {
					let chroma = resolved.chroma(gun.skin.chroma)
					let icon = chroma?.displayIcon ?? chroma?.fullRender ?? resolved.displayIcon
					icon.asyncImageOrPlaceholder()
						.frame(height: 80)
						.padding(.vertical)
					
					if resolved.skin.chromas.count > 1 {
						chromaPicker
					}
					
					if resolved.skin.levels.count > 1 {
						levelPicker
					}
					
					NavigationLink("Change Skin") {
						skinPicker
					}
				}
				.frame(maxWidth: .infinity)
			}
			
			Section("Buddy") {
				ZStack {
					if let buddy = gun.buddy {
						let info = assets?.buddies[buddy.buddy]
						VStack {
							(info?.displayIcon).asyncImageOrPlaceholder()
								.frame(width: 60)
							Text(info?.displayName ?? "<unknown buddy>")
						}
					} else {
						Text("No buddy selected!")
							.foregroundColor(.secondary)
					}
					
					Text("").frame(maxWidth: .infinity, alignment: .leading)
				}
				.frame(maxWidth: .infinity)
				
				NavigationLink("Change Buddy") {
					BuddyPicker(loadout: $loadout, weapon: gun.id, inventory: inventory)
				}
			}
		}
		.navigationTitle("Customize \(assets?.weapons[gun.id]?.displayName ?? "Gun")")
		.navigationBarTitleDisplayMode(.inline)
	}
	
	var chromaPicker: some View {
		let spacing = 6.0
		let size = 32.0 + 2 * spacing
		
		return HStack(spacing: spacing) {
			ForEach(resolved.skin.chromas.indexed(), id: \.element.id) { index, chroma in
				let isOwned = index == 0 || inventory.skinChromas.contains(chroma.id)
				Button {
					gun.skin.chroma = chroma.id
				} label: {
					ZStack {
						if chroma.id == gun.skin.chroma {
							let shape = RoundedRectangle(cornerRadius: spacing, style: .continuous)
							shape.blendMode(.destinationOut)
							shape.stroke(Color.accentColor, lineWidth: 2)
						}
						
						chroma.swatch.asyncImageOrPlaceholder()
							.padding(spacing)
					}
				}
				.buttonStyle(.plain)
				.frame(width: size, height: size)
				.disabled(!isOwned)
				.saturation(isOwned ? 1 : 0)
				.opacity(isOwned ? 1 : 0.5)
			}
		}
		.padding(spacing)
		.background(Color.primary.opacity(0.1))
		.cornerRadius(2 * spacing)
		.compositingGroup()
	}
	
	var levelPicker: some View {
		ZStack {
			HStack(alignment: .top, spacing: 2) {
				ForEach(resolved.skin.levels.indexed(), id: \.element.id) { index, level in
					let isOwned = index == 0 || inventory.skinLevels.contains(level.id)
					let isActive = resolved.levelIndex >= index
					
					if index > 0 {
						Rectangle().frame(height: 2)
							.offset(y: 21) // sorry lol
							.frame(maxWidth: 32)
							.foregroundColor(isActive ? .accentColor : .secondary)
							.opacity(0.25)
							.opacity(isOwned ? 1 : 0.5)
							.zIndex(-1)
					}
					
					VStack {
						Button {
							gun.skin.level = level.id
						} label: {
							ZStack {
								let isSelected = gun.skin.level == level.id
								Circle()
									.foregroundColor(isSelected ? .accentColor : .secondary.opacity(0.25))
									.foregroundColor(.secondary.opacity(0.25))
								Text("\(index + 1)")
									.font(.callout)
									.foregroundColor(isSelected ? .white : .accentColor)
									.foregroundColor(.accentColor)
								
								if true, isSelected {
									Circle().stroke(lineWidth: 6).blendMode(.destinationOut)
									Circle().stroke(Color.accentColor, lineWidth: 2)
								}
							}
							.frame(height: 44)
						}
						.disabled(!isOwned)
						.buttonStyle(.plain)
						
						if let item = level.levelItem {
							Text(item.description)
								.lineLimit(3)
								.multilineTextAlignment(.center)
								.font(.caption)
								.foregroundColor(.secondary)
								.frame(width: 72)
								.fixedSize()
								.frame(width: 1) // fake smaller width
								.opacity(isOwned ? 1 : 0.5)
						}
					}
				}
			}
			.compositingGroup()
			
			HStack {
				Text("") // the separator insets to the leftmost text it finds
				Spacer()
			}
		}
	}
	
	@ViewBuilder
	var skinPicker: some View {
		if let weapon = assets?.weapons[gun.id] {
			let skins: [ResolvedLevel] = weapon.skins.map {
				let index = $0.levels.lastIndex { inventory.skinLevels.contains($0.id) } ?? 0
				return ResolvedLevel(weapon: weapon, skin: $0, level: $0.levels[index], levelIndex: index)
			}
			SearchableAssetPicker(
				allItems: .init(values: skins),
				ownedItems: .init(skins.lazy.map(\.id).filter(inventory.skinLevels.contains)),
				rowContent: skinPickerRow(for:)
			)
			.navigationTitle("Choose Skin")
		}
	}
	
	@ViewBuilder
	func skinPickerRow(for skin: ResolvedLevel) -> some View {
		let isSelected = gun.skin.skin == skin.skin.id
		VStack {
			skin.displayIcon?.asyncImage()
				.frame(height: 60)
				.frame(maxWidth: .infinity)
			
			SelectableRow(isSelected: isSelected) {
				gun.skin = .init(
					skin: skin.skin.id,
					level: skin.level.id,
					chroma: skin.skin.chromas.first!.id
				)
			} content: {
				Text(skin.displayName)
					.frame(maxWidth: .infinity, alignment: .leading)
					.foregroundColor(.primary)
			}
		}
		.padding(.vertical, 8)
		.listRowBackground(ZStack {
			Color.secondaryGroupedBackground
			Color.accentColor.opacity(isSelected ? 0.1 : 0)
		})
	}
}

struct BuddyPicker: View {
	@Binding var loadout: UpdatableLoadout
	var weapon: Weapon.ID
	var inventory: Inventory
	@State private var search = ""
	@State private var isAssigningBuddy = false
	@State private var buddyToAssign: BuddyInfo?
	
	@Environment(\.assets) private var assets
	
	var body: some View {
		buddyList
			.confirmationDialog(
				"Out of instances!",
				isPresented: $isAssigningBuddy,
				titleVisibility: .visible,
				presenting: buddyToAssign
			) { buddy in
				let level = buddy.levels.first!
				ForEach((inventory.buddies[level.id] ?? []).indexed(), id: \.element) { index, instance in
					let currentOwner = loadout.guns.values.first { $0.buddy?.instance == instance }!.id
					Button {
						loadout.guns[currentOwner]!.buddy = nil
						loadout.guns[weapon]!.buddy = .init(
							buddy: buddy.id,
							level: level.id,
							instance: instance
						)
					} label: {
						let name = assets?.weapons[currentOwner]?.displayName ?? "unknown gun"
						Text("\(name)")
					}
				}
			} message: { buddy in
				Text("Choose a weapon to take \(buddy.displayName) from.")
			}
			.navigationTitle("Choose Buddy")
	}
	
	var buddyList: some View {
		AssetsUnwrappingView { assets in
			List {
				let ownedItems = inventory.buddies.keys
				let allItems = Dictionary(uniqueKeysWithValues: assets.buddies.values.map { ($0.levels.first!.id, $0) })
				
				let lowerSearch = search.lowercased()
				let results = ownedItems
					.lazy
					.compactMap { allItems[$0] }
					.filter { $0.searchableText.lowercased().hasPrefix(lowerSearch) }
					.sorted(on: \.searchableText)
				
				let selection = loadout.guns[weapon]?.buddy?.instance
				
				Section {
					ForEach(results) { buddy in
						let instances = inventory.buddies[buddy.levels.first!.id] ?? []
						SelectableRow(isSelected: instances.contains { $0 == selection }) {
							assign(buddy)
						} content: {
							buddy.displayIcon.asyncImage()
								.frame(width: 48, height: 48)
							Text(buddy.displayName)
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
	}
	
	func assign(_ buddy: BuddyInfo) {
		let level = buddy.levels.first!
		let instances = inventory.buddies[buddy.levels.first!.id] ?? []
		let unowned = instances.first { instance in
			let currentOwner = loadout.guns.values.first { $0.buddy?.instance == instance }?.id
			return currentOwner == nil
		}
		
		if let instance = unowned {
			loadout.guns[weapon]!.buddy = .init(
				buddy: buddy.id,
				level: level.id,
				instance: instance
			)
		} else {
			buddyToAssign = buddy
			isAssigningBuddy = true
		}
	}
}

extension ResolvedLevel: SearchableAsset {
	var searchableText: String {
		level.displayName ?? skin.displayName
	}
}

extension BuddyInfo: SearchableAsset {
	var searchableText: String { displayName }
}

#if DEBUG
struct GunCustomizer_Previews: PreviewProvider, PreviewProviderWithAssets {
	static func previews(assets: AssetCollection) -> some View {
		let gun = PreviewData.loadout.guns[13]
		GunCustomizer(
			gun: .constant(gun),
			loadout: .constant(.init(PreviewData.loadout)),
			resolved: assets.resolveSkin(gun.skin.level)!,
			inventory: PreviewData.inventory
		)
		.withToolbar()
		.previewDisplayName("Gun Customizer")
	}
}
#endif
