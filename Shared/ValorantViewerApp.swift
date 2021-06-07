import SwiftUI
import KeychainSwift

@main
struct ValorantViewerApp: App {
	private var isTesting: Bool {
		ProcessInfo.processInfo.environment["XCInjectBundleInto"] != nil
	}
	
	var body: some Scene {
		WindowGroup {
			if !isTesting {
				ContentView(
					dataStore: ClientDataStore(keychain: KeychainSwift(), for: StandardClientData.self)
				)
				.environmentObject(AssetManager())
			}
		}
	}
}
