import SwiftUI

struct AccountView: View {
	@ObservedObject var dataStore: ClientDataStore
	@ObservedObject var assetManager: AssetManager
	
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
		if let user = dataStore.data?.user {
			VStack(spacing: 20) {
				Text("Signed in as \(Text(user.name).fontWeight(.semibold))")
					.font(.title3)
					.multilineTextAlignment(.center)
				
				Button("Sign Out") {
					dataStore.data = nil
				}
			}
			.padding()
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
				
				Button("Retry", role: nil) { await assetManager.loadAssets() }
				
				Text(error.localizedDescription)
			} else if assetManager.assets == nil {
				Text("Missing assets!")
					.font(.headline)
					.fontWeight(.medium)
				Text("Anything with images will not display correctly.")
					.multilineTextAlignment(.center)
				
				Button("Download Assets Now", role: nil) { await assetManager.loadAssets() }
			} else {
				Text("Assets up to date!")
					.foregroundStyle(.secondary)
				
				Button("Redownload", role: nil) { await assetManager.loadAssets(forceUpdate: true) }
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
