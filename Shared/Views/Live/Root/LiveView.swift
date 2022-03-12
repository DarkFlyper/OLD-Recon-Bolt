import SwiftUI
import ValorantAPI
import HandyOperators

struct LiveView: View {
	let userID: User.ID
	@State var contractDetails: ContractDetails?
	@State var offers: [StoreOffer.ID: StoreOffer]?
	@State var storefront: Storefront?
	
	@Environment(\.valorantLoad) private var load
	@Environment(\.scenePhase) private var scenePhase
	
	var body: some View {
		ScrollView {
			VStack(spacing: 20) {
				LiveGameBox(userID: userID)
				
				missionsBox
				
				storeBox
			}
			.padding()
			.compositingGroup() // avoid shadows overlapping other boxes
			.shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
		}
		.task(loadContractDetails)
		.task(loadStoreDetails)
		.onSceneActivation(perform: loadContractDetails)
		.onSceneActivation(perform: loadStoreDetails)
		.background(Color(.systemGroupedBackground))
		.navigationTitle("Live")
	}
	
	// TODO: eliminate repetition between these two boxes
	
	var missionsBox: some View {
		RefreshableBox(title: "Missions", refreshAction: loadContractDetails) {
			if let details = contractDetails {
				ContractDetailsView(details: details)
			} else {
				Divider()
				
				GroupBox {
					Text("Missions not loaded!")
						.foregroundColor(.secondary)
				}
				.padding(16)
			}
		}
	}
	
	var storeBox: some View {
		RefreshableBox(title: "Store", refreshAction: loadStoreDetails) {
			if let offers = offers, let storefront = storefront {
				StoreDetailsView(offers: offers, storefront: storefront)
			} else {
				Divider()
				
				GroupBox {
					Text("Store not loaded!")
						.foregroundColor(.secondary)
				}
				.padding(16)
			}
		}
	}
	
	@Sendable
	func loadContractDetails() async {
		await load {
			contractDetails = try await $0.getContractDetails()
		}
	}
	
	@Sendable
	func loadStoreDetails() async {
		// load independently & concurrently
		await load {
			async let offers = $0.getStoreOffers()
			async let storefront = $0.getStorefront(for: userID)
			self.offers = try await .init(values: offers)
			self.storefront = try await storefront
		}
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
		.inEachColorScheme()
	}
}
#endif
