import SwiftUI
import Combine
import HandyOperators
import ValorantAPI

struct ContentView: View {
	@State private var isLoggingIn = false
	
	@State var matchList: MatchList?
	
	@EnvironmentObject private var loadManager: LoadManager
	
	var body: some View {
		matchListView
			.onAppear {
				guard loadManager.client == nil else { return }
				isLoggingIn = true
			}
			.onChange(of: loadManager.client?.id) { _ in
				isLoggingIn = false
				loadMatches()
			}
			.navigationTitle(matchList?.user.account.name ?? "Matches")
			.toolbar {
				ToolbarItemGroup(placement: .trailing) {
					Button("Account") { isLoggingIn = true }
				}
			}
			.sheet(isPresented: $isLoggingIn) {
				LoginSheet(client: $loadManager.client)
					.withLoadManager()
			}
			.loadErrorTitle("Could not load matches!")
			.withToolbar()
			.environment(\.playerID, matchList?.user.id)
	}
	
	@ViewBuilder
	private var matchListView: some View {
		if let matchList = Binding($matchList) {
			MatchListView(matchList: matchList)
		} else {
			Text("Not signed in!")
				.frame(maxWidth: .infinity, maxHeight: .infinity)
		}
	}
	
	func loadMatches() {
		loadManager.load { client in client
			.getUserInfo()
			.map(MatchList.forUser)
			.flatMap { matchList in
				matchList.matches.isEmpty
					? client.loadOlderMatches(for: matchList)
					: Just(matchList).setFailureType(to: Error.self).eraseToAnyPublisher()
			}
		} onSuccess: { matchList = $0 }
	}
}

struct ContentView_Previews: PreviewProvider {
	static let exampleMatchData = try! Data(
		contentsOf: Bundle.main
			.url(forResource: "example_matches", withExtension: "json")!
	)
	static let exampleMatches = try! Client.responseDecoder
		.decode([CompetitiveUpdate].self, from: exampleMatchData)
	static let exampleUser = UserInfo(
		account: .init(
			gameName: "Julian", tagLine: "665",
			createdAt: Date().addingTimeInterval(-4000)
		),
		id: .init()
	)
	static let exampleMatchList = MatchList(
		user: exampleUser,
		chronology: .init(entries: exampleMatches)
	)
	
	static var previews: some View {
		ContentView(matchList: exampleMatchList)
			.preferredColorScheme(.light)
		ContentView(matchList: exampleMatchList)
			.preferredColorScheme(.dark)
	}
}
