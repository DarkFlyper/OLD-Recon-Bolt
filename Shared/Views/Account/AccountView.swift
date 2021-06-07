import SwiftUI

struct AccountView: View {
	@EnvironmentObject private var dataStore: ClientDataStore
	@EnvironmentObject private var assetManager: AssetManager
	
	var body: some View {
		ScrollView {
			VStack {
				if let user = dataStore.data?.user {
					VStack(spacing: 20) {
						(Text("Signed in as ") + Text(verbatim: user.account.name).fontWeight(.semibold))
							.font(.title2)
							.multilineTextAlignment(.center)
						
						Button("Sign Out") {
							dataStore.data = nil
						}
					}
				} else {
					LoginForm(data: $dataStore.data, credentials: .init(from: dataStore.keychain) ?? .init())
						.withLoadManager()
				}
				
				Spacer()
				
				if let progress = assetManager.progress {
					VStack {
						Text("\(progress.completed)/\(progress.total) Assets Downloaded…")
						
						ProgressView(value: progress.fractionComplete)
					}
					.padding()
				}
			}
			.padding(.top, 40)
		}
		.navigationTitle("Account")
		.withToolbar()
	}
}

#if DEBUG
struct AccountView_Previews: PreviewProvider {
	static var previews: some View {
		AccountView()
			.withMockData()
		
		AccountView()
			.withValorantLoadManager()
			.environmentObject(ClientDataStore(keychain: MockKeychain(), for: EmptyClientData.self))
			.environmentObject(AssetManager.mockDownloading)
	}
}
#endif
