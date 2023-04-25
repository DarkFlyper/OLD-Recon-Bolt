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
		
		LoadoutCustomizer(loadout: loadoutBinding, inventory: inventory)
			.buttonBorderShape(.capsule)
			.padding(.bottom)
			.task(id: fetchedLoadout.version) {
				loadout = .init(fetchedLoadout)
			}
	}
}

extension LoadoutDetailsView {
	init(loadout: Loadout, inventory: Inventory) {
		self.init(fetchedLoadout: loadout, loadout: .init(loadout), inventory: inventory)
	}
}

private struct LoadoutCustomizer: View {
	@Binding var loadout: UpdatableLoadout
	var inventory: Inventory
	
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
					Image(systemName: "chevron.forward")
				}
			}
			.buttonStyle(.bordered)
		}
	}
	
	var cardPicker: some View {
		NavigationLink {
			PlayerCardPicker(selection: $loadout.identity.card, inventory: inventory)
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
			PlayerTitlePicker(selection: $loadout.identity.title, inventory: inventory)
		} label: {
			HStack {
				PlayerTitleLabel(titleID: loadout.identity.title)
				
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
				SprayCell(slot: slot, spray: $loadout.sprays[slot], inventory: inventory)
			}
			.frame(maxWidth: 128)
		}
		.padding(.horizontal)
	}
	
	struct SprayCell: View {
		var slot: Spray.Slot.ID
		@Binding var spray: Spray.ID?
		var inventory: Inventory
		
		@Environment(\.assets) private var assets
		
		var body: some View {
			NavigationLink {
				SprayPicker(selection: $spray, inventory: inventory, isMidRound: slot == .midRound)
			} label: {
				VStack {
					if let spray {
						let info = assets?.sprays[spray]
						(info?.bestIcon).view()
							.aspectRatio(1, contentMode: .fit)
					} else {
						Color.clear
					}
					
					slot.name
						.font(.caption)
						.foregroundColor(.secondary)
				}
			}
			.buttonStyle(.bordered)
			.buttonBorderShape(.roundedRectangle(radius: 8))
		}
	}
}

extension Spray.Slot.ID {
	var name: Text {
		switch self {
		case .preRound:
			return Text("pre-round", comment: "Loadout: spray slot")
		case .midRound:
			return Text("mid-round", comment: "Loadout: spray slot")
		case .postRound:
			return Text("post-round", comment: "Loadout: spray slot")
		default:
			return Text("slot", comment: "Loadout: unknown spray slot (should never appear unless Riot changes something)")
		}
	}
}

#if DEBUG
struct LoadoutDetailsView_Previews: PreviewProvider {
	static var previews: some View {
		RefreshableBox(title: "Loadout", isExpanded: .constant(true)) {
			LoadoutDetailsView(loadout: PreviewData.loadout, inventory: PreviewData.inventory)
		} refresh: { _ in }
			.forPreviews()
			.navigationTitle("Loadout")
			.withToolbar()
	}
}
#endif
