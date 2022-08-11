import SwiftUI
import ValorantAPI

struct AccountView: View {
	@ObservedObject var dataStore: ClientDataStore
	@ObservedObject var assetManager: AssetManager
	
	@LocalData var user: User?
	@State var newestVersion: AssetVersion?
	
	var body: some View {
		ScrollView {
			VStack {
				accountInfo
				
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
					if let user = user {
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
	
	@ViewBuilder
	var assetsInfo: some View {
		VStack(spacing: 12) {
			if let progress = assetManager.progress {
				if let total = progress.total {
					Text("\(progress.completed)/\(total) Images Downloaded…")
				} else {
					Text("Preparing…")
				}
				
				ProgressView(value: progress.fractionComplete)
			} else if let error = assetManager.error {
				Text("Error downloading assets!")
					.font(.headline)
				
				AsyncButton("Retry") { await assetManager.loadAssets() }
				
				Text(String(describing: error))
					.font(.caption)
			} else if let assets = assetManager.assets {
				if let newestVersion = newestVersion, assets.version != newestVersion {
					Text("Assets out of date!")
						.font(.headline)
					
					VStack(alignment: .trailing) {
						Text("Current version: \(assets.version.version)")
						Text("Newest available: \(newestVersion.version)")
					}
					.foregroundStyle(.secondary)
					.font(.callout.monospacedDigit())
					
					HStack {
						AsyncButton("Full Update") {
							await assetManager.loadAssets()
						}
						.buttonStyle(.borderedProminent)
						
						AsyncButton("Quick Update") {
							await assetManager.loadAssets(skipExistingImages: true)
						}
					}
					
					Text("Quick Update is a faster but less reliable way to update: only downloads missing images; does not update existing images that have changed.")
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
					
					AsyncButton("Redownload") {
						await assetManager.loadAssets(forceUpdate: true)
					}
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
		AccountView(dataStore: PreviewData.emptyDataStore, assetManager: .mockDownloading)
		AccountView(dataStore: PreviewData.emptyDataStore, assetManager: .mockEmpty)
	}
}
#endif
