import SwiftUI
import ValorantAPI

struct SettingsView: View {
	@ObservedObject var accountManager: AccountManager
	@ObservedObject var assetManager: AssetManager
	@ObservedObject var appSettings: AppSettings
	
	var body: some View {
		Form {
			AccountSettingsView(accountManager: accountManager)
			
			Section("Settings") {
				NavigationLink("Manage Assets") {
					AssetsInfoView(assetManager: assetManager)
				}
				
				if let activeAccount = accountManager.activeAccount {
					NavigationLink("Request Log") {
						ClientLogView(client: activeAccount.client)
					}
				}
				
				Picker("Theme", selection: $appSettings.theme) {
					ForEach(AppSettings.Theme.allCases, id: \.self) { theme in
						Text(theme.name)
							.tag(theme)
					}
				}
			}
			
			Section("About") {
				NavigationLink {
					AboutScreen()
				} label: {
					Label("About Recon Bolt", systemImage: "questionmark")
				}
				
				ListLink("Rate on the App Store", icon: "star", destination: "https://apps.apple.com/app/recon-bolt/id1563649061?action=write-review")
				
				ListLink("Join the Discord Server", icon: "bubble.left.and.bubble.right", destination: "https://discord.gg/bwENMNRqNa")
			}
		}
		.navigationTitle("Settings")
		.withToolbar()
	}
}

private extension AppSettings.Theme {
	var name: LocalizedStringKey {
		switch self {
		case .system:
			return "Match System"
		case .light:
			return "Light Mode"
		case .dark:
			return "Dark Mode"
		}
	}
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
	static var previews: some View {
		SettingsView(accountManager: .mocked, assetManager: .forPreviews, appSettings: .init())
		SettingsView(accountManager: .mockEmpty, assetManager: .mockEmpty, appSettings: .init())
	}
}
#endif
