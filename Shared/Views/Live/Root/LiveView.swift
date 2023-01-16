import SwiftUI
import ValorantAPI
import HandyOperators
import UserDefault

struct LiveView: View {
	let userID: User.ID
	@State var contractDetails: ContractDetails?
	@State fileprivate var loadoutInfo: LoadoutInfo?
	@State fileprivate var storeInfo: StoreInfo?
	
	@UserDefault.State("LiveView.expandedBoxes")
	var expandedBoxes: Set<Box> = [.party]
	
	@Environment(\.valorantLoad) private var load
	@Environment(\.assets) private var assets
	
	var body: some View {
		ScrollView {
			VStack(spacing: 16) {
				LiveGameBox(userID: userID, isExpanded: $expandedBoxes.contains(.party))
				
				missionsBox
				
				loadoutBox
				
				storeBox
			}
			.padding()
			.compositingGroup() // avoid shadows overlapping other boxes
			.shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
		}
		.background(Color.groupedBackground)
		.navigationTitle("Live")
	}
	
	var missionsBox: some View {
		RefreshableBox(title: "Missions", isExpanded: $expandedBoxes.contains(.missions)) {
			infoOrPlaceholder(placeholder: "Missions not loaded!", contractDetails) {
				ContractDetailsView(contracts: .init(details: $0, assets: assets))
			}
		} refresh: {
			contractDetails = try await $0.getContractDetails()
		}
	}
	
	var loadoutBox: some View {
		RefreshableBox(title: "Loadout", isExpanded: $expandedBoxes.contains(.loadout)) {
			infoOrPlaceholder(placeholder: "Loadout not loaded!", loadoutInfo) { info in
				LoadoutDetailsView(loadout: info.loadout, inventory: info.inventory)
			}
		} refresh: {
			loadoutInfo = try await .init(using: $0)
		}
	}
	
	var storeBox: some View {
		RefreshableBox(title: "Store", isExpanded: $expandedBoxes.contains(.store)) {
			infoOrPlaceholder(placeholder: "Store not loaded!", storeInfo) { info in
				StoreDetailsView(
					updateTime: info.updateTime,
					offers: info.offers, storefront: info.storefront, wallet: info.wallet)
			}
		} refresh: {
			storeInfo = try await .init(using: $0)
		}
	}
	
	@ViewBuilder
	func infoOrPlaceholder<Data, Content: View>(
		placeholder: LocalizedStringKey,
		_ data: Data?,
		@ViewBuilder content: (Data) -> Content
	) -> some View {
		if let data {
			content(data)
		} else {
			Divider()
			
			GroupBox {
				Text(placeholder)
					.foregroundColor(.secondary)
			}
			.padding(16)
		}
	}
	
	enum Box: String, Hashable, DefaultsValueConvertible {
		typealias DefaultsRepresentation = String
		
		case party
		case missions
		case loadout
		case store
	}
}

private struct LoadoutInfo {
	var loadout: Loadout
	var inventory: Inventory
	
	init(using client: ValorantClient) async throws {
		async let loadout = client.getLoadout()
		async let inventory = client.getInventory()
		self.loadout = try await loadout
		self.inventory = try await inventory
	}
}

private struct StoreInfo {
	var updateTime: Date
	var offers: [StoreOffer.ID: StoreOffer]
	var storefront: Storefront
	var wallet: StoreWallet
}

extension StoreInfo {
	init(using client: ValorantClient) async throws {
		async let offers = client.getStoreOffers()
		async let storefront = client.getStorefront()
		async let wallet = client.getStoreWallet()
		
		self.offers = try await .init(values: offers)
		self.storefront = try await storefront
		self.wallet = try await wallet
		self.updateTime = .now
	}
}

struct ActiveMatch: Hashable {
	var id: Match.ID
	var inPregame: Bool
}

extension ValorantClient {
	func getActiveMatch() async throws -> ActiveMatch? {
		async let liveGame = getLiveMatch(inPregame: false)
		async let livePregame = getLiveMatch(inPregame: true)
		
		if let match = try await liveGame {
			return .init(id: match, inPregame: false)
		} else if let match = try await livePregame {
			return .init(id: match, inPregame: true)
		} else {
			return nil
		}
	}
}

#if DEBUG
struct LiveView_Previews: PreviewProvider {
	static var previews: some View {
		LiveView(
			userID: PreviewData.userID,
			contractDetails: PreviewData.contractDetails
		)
		.withToolbar()
	}
}
#endif
