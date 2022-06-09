import SwiftUI
import ValorantAPI

struct GunCustomizer: View {
	@Binding var gun: Loadout.Gun
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
		}
		.navigationTitle("Customize \(assets?.weapons[gun.id]?.displayName ?? "Gun")")
		.navigationBarTitleDisplayMode(.inline)
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
			
			Button {
				gun.skin.skin = skin.skin.id
				gun.skin.level = skin.level.id
			} label: {
				HStack {
					Text(skin.displayName)
						.frame(maxWidth: .infinity, alignment: .leading)
						.foregroundColor(.primary)
					
					Image(systemName: "checkmark.circle.fill")
						.opacity(isSelected ? 1 : 0)
				}
			}
		}
		.padding(.vertical, 8)
		.listRowBackground(ZStack {
			Color.secondaryGroupedBackground
			Color.accentColor.opacity(isSelected ? 0.1 : 0)
		})
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
}

extension ResolvedLevel: SearchableAsset {
	var searchableText: String {
		level.displayName ?? skin.displayName
	}
}

#if DEBUG
struct GunCustomizer_Previews: PreviewProvider, PreviewProviderWithAssets {
	static func previews(assets: AssetCollection) -> some View {
		let gun = PreviewData.loadout.guns[13]
		GunCustomizer(
			gun: .constant(gun),
			resolved: assets.resolveSkin(gun.skin.level)!,
			inventory: PreviewData.inventory
		)
		.withToolbar()
		.previewDisplayName("Gun Customizer")
	}
}
#endif
