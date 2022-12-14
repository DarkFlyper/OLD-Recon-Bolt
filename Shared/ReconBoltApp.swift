import SwiftUI

// TODO: remove this when FB9309847 (using implicit CGFloat–Double conversion breaks preview bounds display) is addressed
typealias FloatLiteralType = CGFloat

@main
struct ReconBoltApp: App {
	@StateObject var accountManager = AccountManager()
	@StateObject var assetManager = AssetManager()
	@StateObject var bookmarkList = BookmarkList()
	@StateObject var imageManager = ImageManager()
	@StateObject var settings = AppSettings()
	@StateObject var store = InAppStore()
	
	private var isTesting: Bool {
		ProcessInfo.processInfo.environment["XCInjectBundleInto"] != nil
	}
	
	var body: some Scene {
		WindowGroup {
			if !isTesting {
				ContentView(
					accountManager: accountManager,
					assetManager: assetManager,
					settings: settings,
					store: store
				)
				.onAppear { ReviewManager.registerUsage(points: 2) }
				.environmentObject(bookmarkList)
				.environmentObject(imageManager)
				.environment(\.assets, assetManager.assets)
				.environment(\.location, accountManager.activeAccount?.location)
				.environment(\.ownsProVersion, store.ownsProVersion)
				.preferredColorScheme(settings.theme.colorScheme)
				.task(id: assetManager.assets?.version) {
					guard let version = assetManager.assets?.version else { return }
					accountManager.clientVersion = version.riotClientVersion
					imageManager.setVersion(version)
				}
				.onOpenURL(perform: handle(_:))
			}
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
}

extension EnvironmentValues {
	var ownsProVersion: Bool {
		get { self[Key.self] }
		set { self[Key.self] = newValue }
	}
	
	private enum Key: EnvironmentKey {
		static let defaultValue = false
	}
}
