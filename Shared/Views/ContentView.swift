import SwiftUI
import HandyOperators
import ValorantAPI
import KeychainSwift

struct ContentView: View {
	@ObservedObject var accountManager: AccountManager
	@ObservedObject var assetManager: AssetManager
	@ObservedObject var settings: AppSettings
	@ObservedObject var store: InAppStore
	
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
			
			SettingsView(accountManager: accountManager, assetManager: assetManager, settings: settings, store: store)
				.tabItem { Label("Settings", systemImage: "gearshape") }
				.tag(Tab.settings)
		}
		.task(id: accountManager.requiresAction) {
			if accountManager.requiresAction {
				tab = .settings
			}
		}
		.sheet(caching: $accountManager.multifactorPrompt) {
			MultifactorPromptView(prompt: $0, didSessionExpire: true)
		} onDismiss: {
			$0.completion(.failure(AccountManager.MultifactorPromptError.cancelled))
		}
		.buttonBorderShape(.capsule)
		.withValorantLoadFunction(manager: accountManager)
		.withLoadErrorAlerts()
		.onSceneActivation {
			Task { await assetManager.loadAssets() }
		}
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
		ContentView(accountManager: .mocked, assetManager: .forPreviews, settings: .init(), store: .init())
		ContentView(accountManager: .mocked, assetManager: .forPreviews, settings: .init(), store: .init(), tab: .live)
		ContentView(accountManager: .mocked, assetManager: .forPreviews, settings: .init(), store: .init(), tab: .reference)
		ContentView(accountManager: .init(), assetManager: .forPreviews, settings: .init(), store: .init())
	}
}
#endif
