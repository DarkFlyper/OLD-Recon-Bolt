import SwiftUI

struct AccountView: View {
	@ObservedObject var dataStore: ClientDataStore
	@EnvironmentObject private var assetManager: AssetManager
	
	var body: some View {
		ScrollView {
			VStack {
				if let user = dataStore.data?.user {
					VStack(spacing: 20) {
						(Text("Signed in as ") + Text(verbatim: user.name).fontWeight(.semibold))
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
				
				Divider()
				
				assetsInfo
					.padding()
			}
			.padding(.vertical)
		}
		.navigationTitle("Account")
		.withToolbar()
	}
	
	@ViewBuilder
	var assetsInfo: some View {
		if let progress = assetManager.progress {
			VStack {
				Text("\(progress.completed)/\(progress.total) Assets Downloaded…")
				
				ProgressView(value: progress.fractionComplete)
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
				.opacity(0.5)
		}
	}
}

#if DEBUG
struct AccountView_Previews: PreviewProvider {
	static var previews: some View {
		AccountView(dataStore: PreviewData.mockDataStore)
			.withPreviewAssets()
		
		AccountView(dataStore: PreviewData.emptyDataStore)
			.environmentObject(AssetManager.mockDownloading)
		
		AccountView(dataStore: PreviewData.emptyDataStore)
			.environmentObject(AssetManager.mockEmpty)
	}
}
#endif
