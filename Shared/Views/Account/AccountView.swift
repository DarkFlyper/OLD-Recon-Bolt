import SwiftUI
import ValorantAPI

struct AccountView: View {
	@ObservedObject var dataStore: ClientDataStore
	@ObservedObject var assetManager: AssetManager
	
	@State var user: User?
	
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
			LoginForm(data: $dataStore.data, credentials: .init(from: dataStore.keychain) ?? .init())
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
					.fontWeight(.semibold)
				
				AsyncButton("Retry") { await assetManager.loadAssets() }
				
				Text(error.localizedDescription)
			} else if let assets = assetManager.assets {
				Text("Assets complete!")
				
				Text("Version \(assets.version.version)")
					.foregroundStyle(.secondary)
				
				AsyncButton("Redownload") { await assetManager.loadAssets(forceUpdate: true) }
			} else {
				Text("Missing assets!")
					.font(.headline)
					.fontWeight(.medium)
				Text("Anything with images will not display correctly.")
					.multilineTextAlignment(.center)
				
				AsyncButton("Download Assets Now") { await assetManager.loadAssets() }
					.tint(.accentColor)
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
