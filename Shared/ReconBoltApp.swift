import SwiftUI
import AVKit

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
	@StateObject var configManager = GameConfigManager()
	
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
				.onAppear { onLaunch() }
				.environmentObject(bookmarkList)
				.environmentObject(imageManager)
				.environmentObject(settings)
				.environmentObject(configManager)
				.environment(\.configs, configManager.configs())
				.environment(\.assets, assetManager.assets)
				.environment(\.location, accountManager.activeAccount?.location)
				.environment(\.ownsProVersion, store.ownsProVersion)
				.preferredColorScheme(settings.theme.colorScheme)
				.task(id: assetManager.assets?.version) {
					guard let version = assetManager.assets?.version else { return }
					accountManager.clientVersion = version.riotClientVersion
					imageManager.setVersion(version)
				}
			}
		}
	}
	
	private func onLaunch() {
		ReviewManager.registerUsage(points: 2)
		
		// make videos play audio even in silent mode
		do {
			try AVAudioSession.sharedInstance().setCategory(.playback)
		} catch {
			print("could not set audio session category: \(error)")
		}
	}
}

extension EnvironmentValues {
	var ownsProVersion: Bool {
		get { self[OwnsProVersionKey.self] }
		set { self[OwnsProVersionKey.self] = newValue }
	}
	
	private enum OwnsProVersionKey: EnvironmentKey {
		static let defaultValue = false
	}
}
