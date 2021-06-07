import SwiftUI
import Combine
import HandyOperators
import ValorantAPI
import KeychainSwift

struct ContentView: View {
	@SceneStorage("ContentView.state") var tab = Tab.career
	
	@EnvironmentObject private var loadManager: ValorantLoadManager
	@EnvironmentObject private var dataStore: ClientDataStore
	
	var body: some View {
		TabView(selection: $tab) {
			matchListView
				.withToolbar()
				.tabItem { Label("Career", systemImage: "square.fill.text.grid.1x2") }
				.tag(Tab.career)
			
			ReferenceView()
				.withToolbar()
				.tabItem { Label("Reference", systemImage: "books.vertical") }
				.tag(Tab.reference)
			
			AccountView()
				.tabItem { Label("Account", systemImage: "person.crop.circle") }
				.tag(Tab.account)
		}
		.listStyle(PrettyListStyle())
		.environment(\.playerID, dataStore.data?.user.id)
		.onAppear {
			if dataStore.data == nil {
				tab = .account
			}
		}
	}
	
	@ViewBuilder
	private var matchListView: some View {
		if let data = Binding(optionalWorkaround: $dataStore.data) {
			MatchListView(matchList: data.matchList)
		} else {
			Text("Not signed in!")
				.frame(maxWidth: .infinity, maxHeight: .infinity)
				.navigationTitle("Matches")
		}
	}
	
	enum Tab: String {
		case career
		case reference
		case account
	}
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		Group {
			ContentView()
				.inEachColorScheme()
			
			ContentView(tab: .account)
		}
		.withMockData()
		
		ContentView()
			.withValorantLoadManager()
			.environmentObject(ClientDataStore(keychain: MockKeychain(), for: EmptyClientData.self))
	}
}
#endif
