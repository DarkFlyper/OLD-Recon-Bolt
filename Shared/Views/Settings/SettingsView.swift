import SwiftUI
import ValorantAPI

struct SettingsView: View {
	@ObservedObject var accountManager: AccountManager
	@ObservedObject var assetManager: AssetManager
	@ObservedObject var appSettings: AppSettings
	
	@State var isSigningIn = false
	
	@LocalData var user: User?
	
	var body: some View {
		Form {
			Section {
				accountInfo
			} header: {
				Text("Account")
			} footer: {
				legalBoilerplate
			}
			.sheet(isPresented: $isSigningIn) {
				LoginForm(
					accountManager: accountManager,
					credentials: accountManager.activeAccount?.session.credentials ?? .init()
				)
				.withLoadErrorAlerts()
			}
			
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
	
	@ViewBuilder
	var accountInfo: some View {
		if let account = accountManager.activeAccount {
			ZStack {
				if account.session.hasExpired {
					HStack {
						Text("Session expired!")
						Spacer()
						Button("Refresh") {
							isSigningIn = true
						}
						.font(.body.bold())
					}
				} else {
					if let user {
						Text("Signed in as \(Text(user.name).fontWeight(.semibold))")
					} else {
						Text("Signed in.")
					}
				}
			}
			.withLocalData($user, id: account.id, shouldAutoUpdate: true)
			
			Button("Sign Out") {
				accountManager.activeAccount = nil
			}
		} else {
			Text("Not signed in yet.")
			
			Button("Sign In") {
				isSigningIn = true
			}
			.font(.body.weight(.medium))
		}
	}
	
	var legalBoilerplate: some View {
		Text("Recon Bolt is not endorsed by Riot Games and does not reflect the views or opinions of Riot Games or anyone officially involved in producing or managing Riot Games properties. Riot Games and all associated properties are trademarks or registered trademarks of Riot Games, Inc")
			.font(.footnote)
			.foregroundStyle(.secondary)
			.frame(maxWidth: .infinity, alignment: .leading)
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
		SettingsView(accountManager: .init(), assetManager: .mockEmpty, appSettings: .init())
	}
}
#endif
