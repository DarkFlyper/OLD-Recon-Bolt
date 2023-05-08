import SwiftUI
import ValorantAPI
import WidgetKit

struct SettingsView: View {
	@ObservedObject var accountManager: AccountManager
	@ObservedObject var assetManager: AssetManager
	@ObservedObject var settings: AppSettings
	@ObservedObject var store: InAppStore
	
	@StateObject var iconManager = AppIconManager()
	
	@Namespace private var storefrontID
	
	var body: some View {
		ScrollViewReader { scrollView in
			Form {
				AccountSettingsView(accountManager: accountManager)
				
				Section(header: Text("Settings", comment: "Settings: section")) {
					mainSettings()
					
					NavigationLink {
						AdvancedSettingsView(accountManager: accountManager, assetManager: assetManager)
					} label: {
						Label("Advanced Settings", systemImage: "gearshape.2")
					}
				}
				
				Section(String(localized: "In-App Store", defaultValue: "Store", comment: "Settings: section")) {
					InAppStorefront(store: store)
						.id(storefrontID)
				}
				
				Section(header: Text("About", comment: "Settings: section")) {
					NavigationLink {
						AboutScreen()
					} label: {
						Label("About Recon Bolt", systemImage: "questionmark")
					}
					
					ListLink("Rate on the App Store", icon: "star", destination: "https://apps.apple.com/app/recon-bolt/id1563649061?action=write-review")
					
					ListLink("Join the Discord Server", icon: "bubble.left.and.bubble.right", destination: "https://discord.gg/bwENMNRqNa")
				}
			}
			.deepLinkHandler { deepLink in
				guard case .inApp(.storefront) = deepLink else { return }
				withAnimation {
					scrollView.scrollTo(storefrontID, anchor: .center)
				}
			}
		}
		.navigationTitle("Settings")
	}
	
	@ViewBuilder
	func mainSettings() -> some View {
		Picker(selection: $settings.theme) {
			ForEach(AppSettings.Theme.allCases, id: \.self) { theme in
				theme.name
					.tag(theme)
			}
		} label: {
			Label {
				Text("Theme", comment: "Settings: picker")
			} icon: {
				Image(systemName: "sun.max")
			}
		}
		
		NavigationLink {
			AppIconPicker(manager: iconManager)
		} label: {
			Label {
				HStack {
					Text("App Icon", comment: "Settings: button")
					Spacer()
					iconManager.currentIcon.name
						.foregroundStyle(.secondary)
				}
			} icon: {
				Image(systemName: "square.dashed")
			}
		}
		
		Toggle(isOn: $settings.vibrateOnMatchFound) {
			Label {
				Text("Vibrate when Match Found", comment: "Settings: toggle")
			} icon: {
				Image(systemName: "bell")
			}
		}
		
		Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
			NavigationLink {} label: { // i just want the chevron lol
				Label {
					HStack {
						Text("Change Language", comment: "Settings: button")
						Spacer()
						Image(systemName: "link")
							.foregroundStyle(.secondary)
					}
				} icon: {
					Image(systemName: "globe")
				}
			}
			.tint(.primary)
		}
	}
}

struct AdvancedSettingsView: View {
	@ObservedObject var accountManager: AccountManager
	@ObservedObject var assetManager: AssetManager
	@StateObject var storageManager = StorageManager()
	@State var hasRefreshedWidgets = false
	
	var body: some View {
		Form {
			Section {
				NavigationLink("Manage Assets") {
					AssetsInfoView(assetManager: assetManager)
				}
				
				if let activeAccount = accountManager.activeAccount {
					NavigationLink {
						ClientLogView(client: activeAccount.client)
					} label: {
						Text("Request Log", comment: "Advanced Settings: button to open request log")
					}
				}
				
				NavigationLink {
					StorageManagementView(manager: storageManager, accountManager: accountManager)
						.withLoadErrorAlerts()
				} label: {
					HStack {
						Text("Manage Local Storage")
						Spacer()
						if let total = try? storageManager.totalBytes?.get() {
							Text(total, format: .byteCount(style: .file))
								.foregroundStyle(.secondary)
						}
					}
				}
			}
			
			Section {
				Button("Force Refresh Widgets") {
					WidgetCenter.shared.reloadAllTimelines()
					hasRefreshedWidgets = true
				}
			} footer: {
				Text("If your widgets seem broken, use this button to request an immediate refresh from iOS.")
			}
			.alert("Widget Refresh Requested", isPresented: $hasRefreshedWidgets) {
				Button("OK") {}
			} message: {
				Text("iOS is a bit finnicky about this, so widgets may not refresh right away—feel free to reboot your device if this doesn't help!")
			}

		}
		.navigationTitle("Advanced Settings")
	}
}

private extension AppSettings.Theme {
	var name: Text {
		switch self {
		case .system:
			return Text("Match System", comment: "App Theme: automatically match the system theme")
		case .light:
			return Text("Light Mode", comment: "App Theme")
		case .dark:
			return Text("Dark Mode", comment: "App Theme")
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
