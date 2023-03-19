import SwiftUI
import HandyOperators
import ValorantAPI

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
				.withToolbar()
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
		.withValorantLoadFunction(manager: accountManager)
		.withLoadErrorAlerts()
		.onSceneActivation {
			Task { await assetManager.loadAssets() }
		}
		.environment(\.deepLink, handle(_:))
		.onOpenURL(perform: handle(_:))
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
	
	func handle(_ url: URL) {
		print("handling", url)
		do {
			if let widgetLink = try WidgetLink(from: url) {
				handle(widgetLink)
			}
		} catch {
			print("could not decode opened url: \(url)")
		}
	}
	
	func handle(_ widgetLink: WidgetLink) {
		print("handling", widgetLink)
		if let account = widgetLink.account {
			do {
				try accountManager.setActive(account)
				print(accountManager.activeAccount!.session.userID)
			} catch {
				print("error setting account to \(account) for widget link")
			}
		}
		// TODO: handle destination (deep link to e.g. store)
	}
	
	func handle(_ link: InAppLink) {
		switch link {
		case .storefront:
			tab = .settings
			// TODO: maybe even reset settings nav path & scroll it to be visible? would require a lot of conditionalizing
		}
	}
	
	enum Tab: String {
		case career
		case live
		case reference
		case settings
	}
}

enum InAppLink {
	case storefront
}

extension EnvironmentValues {
	var deepLink: (InAppLink) -> Void {
		get { self[DeepLinkKey.self] }
		set { self[DeepLinkKey.self] = newValue }
	}
	
	struct DeepLinkKey: EnvironmentKey {
		static var defaultValue: (InAppLink) -> Void = {
			print("no deep link handler installed; ignoring", $0)
		}
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
