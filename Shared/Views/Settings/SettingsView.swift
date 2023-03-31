import SwiftUI
import ValorantAPI
import WidgetKit

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
				
				Toggle("Vibrate when Match Found", isOn: $settings.vibrateOnMatchFound)
				
				NavigationLink("Advanced Settings") {
					AdvancedSettingsView(accountManager: accountManager, assetManager: assetManager)
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

struct AdvancedSettingsView: View {
	@ObservedObject var accountManager: AccountManager
	@ObservedObject var assetManager: AssetManager
	@StateObject var storageManager = StorageManager()
	
	var body: some View {
		Form {
			Section {
				NavigationLink("Manage Assets") {
					AssetsInfoView(assetManager: assetManager)
				}
				
				if let activeAccount = accountManager.activeAccount {
					NavigationLink("Request Log") {
						ClientLogView(client: activeAccount.client)
					}
				}
				
				NavigationLink {
					StorageManagementView(manager: storageManager, accountManager: accountManager)
						.withLoadErrorAlerts()
				} label: {
					HStack {
						Text("Manage Local Storage")
						Spacer()
						if let total = storageManager.totalBytes {
							Text(total, format: .byteCount(style: .file))
								.foregroundStyle(.secondary)
						}
					}
				}
			}
			
			Section {
				Button("Force Refresh Widgets") {
					WidgetCenter.shared.reloadAllTimelines()
				}
			} footer: {
				Text("If your widgets seem broken, use this button to request an immediate refresh from iOS.")
			}
		}
		.navigationTitle("Advanced Settings")
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
		
		AdvancedSettingsView(accountManager: .mocked, assetManager: .forPreviews)
			.withToolbar()
			.previewDisplayName("Advanced Settings")
		
		SettingsView(accountManager: .mockEmpty, assetManager: .mockEmpty, settings: .init(), store: .init())
			.withToolbar()
			.previewDisplayName("Empty Managers")
		
		AppIconPicker(manager: .init())
			.withToolbar()
			.previewDisplayName("App Icon Picker")
	}
}
#endif
