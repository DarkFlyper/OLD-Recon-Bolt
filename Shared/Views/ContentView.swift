import SwiftUI
import HandyOperators
import ValorantAPI
import KeychainSwift

struct ContentView: View {
	@StateObject var dataStore: ClientDataStore
	#if DEBUG
	@StateObject var assetManager = isInSwiftUIPreview ? .forPreviews : AssetManager()
	#else
	@StateObject var assetManager = AssetManager()
	#endif
	
	@SceneStorage("tab")
	var tab = Tab.career
	
	var body: some View {
		TabView(selection: $tab) {
			onlineView { client in
				BookmarkListView(userID: client.userID)
					.withToolbar()
			}
			.tabItem { Label("Career", systemImage: "square.fill.text.grid.1x2") }
			.tag(Tab.career)
			
			onlineView { client in
				LiveView(userID: client.userID)
					.withToolbar()
			}
			.tabItem { Label("Live", systemImage: "play.circle") }
			.tag(Tab.live)
			
			ReferenceView()
				.withToolbar()
				.tabItem { Label("Reference", systemImage: "books.vertical") }
				.tag(Tab.reference)
			
			AccountView(dataStore: dataStore, assetManager: assetManager)
				.tabItem { Label("Account", systemImage: "person.crop.circle") }
				.tag(Tab.account)
		}
		.onAppear {
			if dataStore.data == nil || assetManager.assets == nil {
				tab = .account
			}
		}
		.withValorantLoadFunction(dataStore: dataStore)
		.withLoadErrorAlerts()
		.environment(\.assets, assetManager.assets)
		.environmentObject(BookmarkList())
	}
	
	@ViewBuilder
	private func onlineView<Content: View>(
		@ViewBuilder content: (ClientData) -> Content
	) -> some View {
		if let data = dataStore.data {
			content(data)
		} else {
			Text("Not signed in!")
				.frame(maxWidth: .infinity, maxHeight: .infinity)
		}
	}
	
	enum Tab: String {
		case career
		case live
		case reference
		case account
	}
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView(dataStore: PreviewData.mockDataStore)
			.inEachColorScheme()
		
		ContentView(dataStore: PreviewData.mockDataStore, tab: .live)
		
		ContentView(dataStore: PreviewData.mockDataStore, tab: .reference)
		
		ContentView(dataStore: PreviewData.emptyDataStore)
	}
}
#endif
