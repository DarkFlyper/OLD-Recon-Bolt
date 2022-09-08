import SwiftUI
import ValorantAPI

struct SettingsView: View {
	@ObservedObject var dataStore: ClientDataStore
	@ObservedObject var assetManager: AssetManager
	
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
					data: $dataStore.data,
					credentials: .init(from: dataStore.keychain) ?? .init(),
					keychain: dataStore.keychain
				)
				.withLoadErrorAlerts()
			}
			
			Section("Settings") {
				NavigationLink("Manage Assets") {
					AssetsInfoView(assetManager: assetManager)
				}
				
				NavigationLink {
					AboutScreen()
				} label: {
					Label("About Recon Bolt", systemImage: "questionmark")
				}
				
				ListLink("Join the Discord Server!", destination: "https://discord.gg/bwENMNRqNa")
			}
		}
		.navigationTitle("Settings")
		.withToolbar()
	}
	
	@ViewBuilder
	var accountInfo: some View {
		if let userID = dataStore.data?.userID {
			ZStack {
				if let user {
					Text("Signed in as \(Text(user.name).fontWeight(.semibold))")
				} else {
					Text("Signed in.")
				}
			}
			.withLocalData($user, id: userID, shouldAutoUpdate: true)
			
			Button("Sign Out") {
				dataStore.data = nil
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

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
	static var previews: some View {
		SettingsView(dataStore: PreviewData.mockDataStore, assetManager: .forPreviews)
		SettingsView(dataStore: PreviewData.emptyDataStore, assetManager: .mockEmpty)
	}
}
#endif
