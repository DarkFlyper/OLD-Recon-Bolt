import SwiftUI
import KeychainSwift

// TODO: remove this when FB9309847 (using implicit CGFloat–Double conversion breaks preview bounds display) is addressed
typealias FloatLiteralType = CGFloat

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
			}
		}
	}
}
