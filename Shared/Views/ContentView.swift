import SwiftUI
import HandyOperators
import ValorantAPI
import KeychainSwift

struct ContentView: View {
	@StateObject var accountManager = AccountManager()
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
			
			SettingsView(accountManager: accountManager, assetManager: assetManager)
				.tabItem { Label("Settings", systemImage: "gearshape") }
				.tag(Tab.settings)
		}
		.task(id: accountManager.requiresAction) {
			if accountManager.requiresAction {
				tab = .settings
			}
		}
		.sheet(caching: $accountManager.multifactorPrompt) {
			MultifactorPromptView(prompt: $0)
		} onDismiss: {
			$0.completion(.failure(AccountManager.MultifactorPromptError.cancelled))
		}
		.buttonBorderShape(.capsule)
		.withValorantLoadFunction(manager: accountManager)
		.withLoadErrorAlerts()
		.environment(\.assets, assetManager.assets)
		.onSceneActivation {
			Task { await assetManager.loadAssets() }
		}
		.task(id: assetManager.assets?.version) {
			guard let version = assetManager.assets?.version else { return }
			accountManager.clientVersion = version.riotClientVersion
			imageManager.setVersion(version)
		}
		.environmentObject(bookmarkList)
		.environmentObject(imageManager)
	}
	
	@ViewBuilder
	private func onlineView<Content: View>(
		@ViewBuilder content: @escaping (User.ID) -> Content
	) -> some View {
		UnwrappingView(
			value: accountManager.activeAccount,
			placeholder: "Not signed in!"
		) { account in
			content(account.id)
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
		ContentView(accountManager: .mocked)
		ContentView(accountManager: .mocked, tab: .live)
		ContentView(accountManager: .mocked, tab: .reference)
		ContentView(accountManager: .init())
	}
}
#endif
