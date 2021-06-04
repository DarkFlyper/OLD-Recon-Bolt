import SwiftUI
import Combine
import HandyOperators
import ValorantAPI
import KeychainSwift

struct ContentView: View {
	@State var tab = Tab.career
	
	@EnvironmentObject private var loadManager: ValorantLoadManager
	@EnvironmentObject private var dataStore: ClientDataStore
	
	var body: some View {
		TabView(selection: $tab) {
			matchListView
				.withToolbar()
				.tabItem { Label("Career", systemImage: "square.fill.text.grid.1x2") }
				.tag(Tab.career)
			
			accountView
				.tabItem { Label("Account", systemImage: "person.crop.circle") }
				.tag(Tab.account)
		}
		.environment(\.playerID, dataStore.data?.user.id)
		.onAppear {
			if dataStore.data == nil {
				tab = .account
			}
		}
	}
	
	@ViewBuilder
	private var matchListView: some View {
		if let matchList = Binding($dataStore.data)?.matchList {
			MatchListView(matchList: matchList)
		} else {
			Text("Not signed in!")
				.frame(maxWidth: .infinity, maxHeight: .infinity)
				.navigationTitle("Matches")
		}
	}
	
	@ViewBuilder
	private var accountView: some View {
		if let user = dataStore.data?.user {
			VStack(spacing: 20) {
				Text("Signed in as \(user.account.name)")
				
				Button("Sign Out") {
					dataStore.data = nil
				}
			}
		} else {
			LoginForm(data: $dataStore.data, credentials: .init(from: dataStore.keychain) ?? .init())
				.withLoadManager()
		}
	}
	
	enum Tab {
		case career
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
