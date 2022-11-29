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
	
	private var isTesting: Bool {
		ProcessInfo.processInfo.environment["XCInjectBundleInto"] != nil
	}
	
	var body: some Scene {
		WindowGroup {
			if !isTesting {
				ContentView(accountManager: accountManager, assetManager: assetManager, settings: settings)
					.onAppear { ReviewManager.registerUsage(points: 2) }
					.environmentObject(bookmarkList)
					.environmentObject(imageManager)
					.environment(\.assets, assetManager.assets)
					.environment(\.location, accountManager.activeAccount?.location)
					.preferredColorScheme(settings.theme.colorScheme)
					.task(id: assetManager.assets?.version) {
						guard let version = assetManager.assets?.version else { return }
						accountManager.clientVersion = version.riotClientVersion
						imageManager.setVersion(version)
					}
			}
		}
	}
}
