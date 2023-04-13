import SwiftUI
import WidgetKit
import ValorantAPI
import HandyOperators
import UserDefault

struct LiveView: View {
	let userID: User.ID
	@State var contractDetails: ContractDetails? {
		didSet {
			if let oldValue, let contractDetails, contractDetails != oldValue {
				WidgetCenter.shared.reloadTimelines(ofKind: "view missions")
			}
		}
	}
	@State fileprivate var loadoutInfo: LoadoutInfo?
	@State fileprivate var storeInfo: StoreInfo?
	
	@UserDefault.State("LiveView.expandedBoxes")
	var expandedBoxes: Set<Box> = [.party]
	
	@LocalData var user: User?
	
	@Environment(\.valorantLoad) private var load
	@Environment(\.assets) private var assets
	@Environment(\.seasons) private var seasons
	
	@Namespace private var missionsBoxID
	@Namespace private var storeBoxID
	
	var body: some View {
		ScrollViewReader { scrollView in
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
			.deepLinkHandler { handle($0, scrollView: scrollView) }
		}
		.navigationTitle("Live")
		.withLocalData($user, id: userID)
		.id(userID) // when user changes, current state is bound to become invalid/irrelevant
		.updatingGameConfig()
	}
	
	var missionsBox: some View {
		RefreshableBox(title: "Missions", isExpanded: $expandedBoxes.contains(.missions)) {
			infoOrPlaceholder(placeholder: "Missions not loaded!", contractDetails) {
				ContractDetailsView(contracts: .init(details: $0, assets: assets, seasons: seasons))
			}
		} refresh: {
			contractDetails = try await $0.getContractDetails()
		}
		.id(missionsBoxID)
	}
	
	var loadoutBox: some View {
		RefreshableBox(title: "Loadout", isExpanded: $expandedBoxes.contains(.loadout)) {
			infoOrPlaceholder(placeholder: "Loadout not loaded!", loadoutInfo) { info in
				LoadoutDetailsView(loadout: info.loadout, inventory: info.inventory)
			}
		} refresh: {
			do {
				loadoutInfo = try await .init(using: $0)
			} catch Loadout.FetchError.uninitialized {
				throw WrongAccountError(user: user)
			}
		}
	}
	
	var storeBox: some View {
		RefreshableBox(title: "Store", isExpanded: $expandedBoxes.contains(.store)) {
			infoOrPlaceholder(placeholder: "Store not loaded!", storeInfo) { info in
				StoreDetailsView(
					updateTime: info.updateTime,
					offers: info.offers, storefront: info.storefront, wallet: info.wallet
				)
			}
		} refresh: {
			storeInfo = try await .init(using: $0)
		}
		.id(storeBoxID)
	}
	
	func handle(_ link: DeepLink, scrollView: ScrollViewProxy) {
		switch link {
		case .widget(let link):
			switch link.destination {
			case .missions:
				expandedBoxes.insert(.missions)
				scrollView.scrollTo(missionsBoxID)
			case .store:
				expandedBoxes.insert(.store)
				scrollView.scrollTo(storeBoxID)
			default:
				break
			}
		default:
			break
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

extension LiveView {
	init(userID: User.ID) {
		self.init(userID: userID, user: .init(id: userID))
	}
}

private struct WrongAccountError: Error, LocalizedError {
	var user: User?
	
	var errorDescription: String? {
		let accountDesc: String
		if let user {
			accountDesc = String(localized: "this one is:\n\n\(user.name)", table: "Errors", comment: "wrong account error")
		} else {
			accountDesc = String(localized: "this one has no Riot ID & Tagline.", table: "Errors", comment: "wrong account error")
		}
		return String(
			localized: """
It looks like this account has never played Valorant!

You've probably signed into the wrong account; \(accountDesc)
""",
			table: "Errors",
			comment: "wrong account error"
		)
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
