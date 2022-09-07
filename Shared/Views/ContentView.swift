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
	@StateObject var bookmarkList = BookmarkList()
	@StateObject var imageManager = ImageManager()
	
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
			
			SettingsView(dataStore: dataStore, assetManager: assetManager)
				.tabItem { Label("Settings", systemImage: "gearshape") }
				.tag(Tab.settings)
		}
		.onAppear {
			if dataStore.data == nil || assetManager.assets == nil {
				tab = .settings
			}
		}
		.onChange(of: dataStore.data == nil) {
			if $0 { tab = .settings }
		}
		.buttonBorderShape(.capsule)
		.withValorantLoadFunction(dataStore: dataStore)
		.withLoadErrorAlerts()
		.environment(\.assets, assetManager.assets)
		.onChange(of: assetManager.assets?.version, perform: { version in
			guard let version else { return }
			Task { await dataStore.data?.setClientVersion(version.riotClientVersion) }
			imageManager.setVersion(version)
		})
		.environmentObject(bookmarkList)
		.environmentObject(imageManager)
	}
	
	@ViewBuilder
	private func onlineView<Content: View>(
		@ViewBuilder content: @escaping (User.ID) -> Content
	) -> some View {
		UnwrappingView(value: dataStore.data, placeholder: "Not signed in!") { data in
			content(data.userID)
		}
	}
	
	enum Tab: String {
		case career
		case live
		case reference
		case settings
	}
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView(dataStore: PreviewData.mockDataStore)
		
		ContentView(dataStore: PreviewData.mockDataStore, tab: .live)
		
		ContentView(dataStore: PreviewData.mockDataStore, tab: .reference)
		
		ContentView(dataStore: PreviewData.emptyDataStore)
	}
}
#endif
