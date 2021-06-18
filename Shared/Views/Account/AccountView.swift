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
				.withLoadManager()
		}
	}
	
	@ViewBuilder
	var assetsInfo: some View {
		if let progress = assetManager.progress {
			VStack {
				Text("\(progress.completed)/\(progress.total) Images Downloaded…")
				
				ProgressView(value: progress.fractionComplete)
			}
		} else if let error = assetManager.error {
			VStack(spacing: 8) {
				Text("Error downloading assets!")
					.font(.headline)
					.fontWeight(.semibold)
				
				Button("Retry", role: nil) { await assetManager.loadAssets() }
				
				Text(error.localizedDescription)
			}
		} else if assetManager.assets == nil {
			VStack(spacing: 8) {
				Text("Missing assets!")
					.font(.headline)
					.fontWeight(.medium)
				Text("Anything with images will not display correctly.")
					.multilineTextAlignment(.center)
				
				Button("Download Assets Now", role: nil) { await assetManager.loadAssets() }
			}
		} else {
			Text("Assets up to date!")
				.foregroundStyle(.secondary)
		}
	}
}

#if DEBUG
struct AccountView_Previews: PreviewProvider {
	static var previews: some View {
		AccountView(dataStore: PreviewData.mockDataStore, assetManager: .forPreviews)
		//AccountView(dataStore: PreviewData.emptyDataStore, assetManager: .mockDownloading)
		//AccountView(dataStore: PreviewData.emptyDataStore, assetManager: .mockEmpty)
	}
}
#endif
