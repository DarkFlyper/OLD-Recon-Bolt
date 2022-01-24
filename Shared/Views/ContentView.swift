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
			onlineView { BookmarkListView(userID: $0) }
				.withToolbar()
				.tabItem { Label("Career", systemImage: "clock") }
				.tag(Tab.career)
			
			onlineView { LiveView(userID: $0) }
				.withToolbar()
				.tabItem { Label("Live", systemImage: "play") }
				.tag(Tab.live)
			
			ReferenceView()
				.withToolbar()
				.tabItem { Label("Reference", systemImage: "book") }
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
		.buttonBorderShape(.capsule)
		.withValorantLoadFunction(dataStore: dataStore)
		.withLoadErrorAlerts()
		.environment(\.assets, assetManager.assets)
		.onChange(of: assetManager.assets?.version, perform: { version in
			guard let clientVersion = version?.riotClientVersion else { return }
			Task { await dataStore.data?.setClientVersion(clientVersion) }
		})
		.environmentObject(BookmarkList())
	}
	
	@ViewBuilder
	private func onlineView<Content: View>(
		@ViewBuilder content: (User.ID) -> Content
	) -> some View {
		if let data = dataStore.data {
			content(data.userID)
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
