import SwiftUI
import ValorantAPI

struct AccountView: View {
	@ObservedObject var dataStore: ClientDataStore
	@ObservedObject var assetManager: AssetManager
	@EnvironmentObject var imageManager: ImageManager
	
	@LocalData var user: User?
	@State var newestVersion: AssetVersion?
	
	var body: some View {
		ScrollView {
			VStack(spacing: 0) {
				accountInfo
				
				Divider()
				
				legalBoilerplate
					.padding()
				
				Divider()
				
				assetsInfo
					.padding()
			}
			.padding(.vertical)
		}
		.buttonStyle(.bordered)
		.navigationTitle("Account")
		.withToolbar()
	}
	
	@ViewBuilder
	var accountInfo: some View {
		if let userID = dataStore.data?.userID {
			VStack(spacing: 20) {
				Group {
					if let user {
						Text("Signed in as \(Text(user.name).fontWeight(.semibold))")
					} else {
						Text("Signed in.")
					}
				}
				.font(.title3)
				.multilineTextAlignment(.center)
				
				Button("Sign Out") {
					dataStore.data = nil
				}
			}
			.padding()
			.withLocalData($user, id: userID, shouldAutoUpdate: true)
		} else {
			LoginForm(
				data: $dataStore.data,
				credentials: .init(from: dataStore.keychain) ?? .init(),
				keychain: dataStore.keychain
			)
			.withLoadErrorAlerts()
		}
	}
	
	var legalBoilerplate: some View {
		Text("Recon Bolt is not endorsed by Riot Games and does not reflect the views or opinions of Riot Games or anyone officially involved in producing or managing Riot Games properties. Riot Games and all associated properties are trademarks or registered trademarks of Riot Games, Inc")
			.font(.footnote)
			.foregroundStyle(.secondary)
			.frame(maxWidth: .infinity, alignment: .leading)
	}
	
	@ViewBuilder
	var assetsInfo: some View {
		VStack(spacing: 12) {
			if let error = assetManager.error {
				Text("Error downloading assets!")
					.font(.headline)
				
				AsyncButton("Retry") { await assetManager.loadAssets() }
				
				Text(String(describing: error))
					.font(.caption)
			} else if let assets = assetManager.assets {
				if let newestVersion, assets.version != newestVersion {
					Text("Assets out of date!")
						.font(.headline)
					
					VStack(alignment: .trailing) {
						Text("Current version: \(assets.version.version)")
						Text("Newest available: \(newestVersion.version)")
					}
					.foregroundStyle(.secondary)
					.font(.callout.monospacedDigit())
					
					AsyncButton("Update Now") {
						await assetManager.loadAssets()
					}
					.buttonStyle(.borderedProminent)
					
					Text("Assets should be fetched automatically, but in case something went wrong, feel free to initiate the process manually.")
						.font(.footnote)
						.foregroundColor(.secondary)
						.frame(maxWidth: .infinity, alignment: .leading)
				} else {
					if newestVersion != nil {
						Text("Assets up to date!")
					} else {
						Text("Assets complete!")
					}
					
					Text("Version \(assets.version.version)")
						.foregroundStyle(.secondary)
						.font(.callout)
					
					AsyncButton("Reset") {
						await assetManager.reset()
						imageManager.clear()
					}
					
					Text("In case something went wrong, use this button to force a full refetch of the assets and images.")
						.font(.footnote)
						.foregroundColor(.secondary)
						.frame(maxWidth: .infinity, alignment: .leading)
				}
			} else {
				Text("Missing assets!")
					.font(.headline)
				Text("Anything with images will not display correctly.")
					.multilineTextAlignment(.center)
				
				AsyncButton("Download Assets Now") { await assetManager.loadAssets() }
					.tint(.accentColor)
			}
		}
		.task {
			do {
				newestVersion = try await AssetClient().getCurrentVersion()
			} catch {
				print("could not fetch newest assets version:", error)
			}
		}
	}
}

#if DEBUG
struct AccountView_Previews: PreviewProvider {
	static var previews: some View {
		AccountView(dataStore: PreviewData.mockDataStore, assetManager: .forPreviews)
		AccountView(dataStore: PreviewData.emptyDataStore, assetManager: .mockEmpty)
	}
}
#endif
