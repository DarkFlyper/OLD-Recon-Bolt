import SwiftUI

@main
struct ValorantViewerApp: App {
	var body: some Scene {
		WindowGroup {
			ContentView()
				.withLoadManager()
		}
	}
}
