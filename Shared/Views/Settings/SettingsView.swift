import SwiftUI
import ValorantAPI

struct SettingsView: View {
	@ObservedObject var accountManager: AccountManager
	@ObservedObject var assetManager: AssetManager
	@ObservedObject var settings: AppSettings
	@ObservedObject var store: InAppStore
	
	@StateObject var iconManager = AppIconManager()
	
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
				
				Toggle("Vibrate when Match Found", isOn: $settings.vibrateOnMatchFound)
				
				Picker("Theme", selection: $settings.theme) {
					ForEach(AppSettings.Theme.allCases, id: \.self) { theme in
						Text(theme.name)
							.tag(theme)
					}
				}
				
				NavigationLink {
					AppIconPicker(manager: iconManager)
				} label: {
					HStack {
						Text("App Icon")
						Spacer()
						Text(iconManager.currentIcon.name)
							.foregroundStyle(.secondary)
					}
				}
			}
			
			Section("Store") {
				InAppStorefront(store: store)
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
		SettingsView(accountManager: .mocked, assetManager: .forPreviews, settings: .init(), store: .init())
			.withToolbar()
		
		SettingsView(accountManager: .mockEmpty, assetManager: .mockEmpty, settings: .init(), store: .init())
			.withToolbar()
			.previewDisplayName("Empty Managers")
		
		AppIconPicker(manager: .init())
			.withToolbar()
			.previewDisplayName("App Icon Picker")
	}
}
#endif
