import SwiftUI

struct AssetsInfoView: View {
	@ObservedObject var assetManager: AssetManager
	@State var newestVersion: AssetVersion?
	
	@EnvironmentObject private var imageManager: ImageManager
	
	var body: some View {
		List {
			if let error = assetManager.error {
				Text("Error downloading assets!")
					.font(.headline)
				
				Text(String(describing: error))
					.font(.caption)
				
				AsyncButton("Retry") { await assetManager.loadAssets() }
			} else if let assets = assetManager.assets {
				if let newestVersion, assets.version != newestVersion {
					VStack(alignment: .leading) {
						Text("Assets out of date!")
							.font(.headline)
						
						VStack(alignment: .trailing) {
							Text("Current version: \(assets.version.version)")
							Text("Newest available: \(newestVersion.version)")
						}
						.foregroundStyle(.secondary)
						.font(.callout.monospacedDigit())
					}
					
					Section {
						AsyncButton("Update Now") {
							await assetManager.loadAssets()
						}
					} header: {
						Text("Repair")
					} footer: {
						Text("Assets should be fetched automatically, but in case something went wrong, feel free to initiate the process manually.")
					}
				} else {
					Section {
						if newestVersion != nil {
							Text("Assets up to date!")
								.font(.headline)
						} else {
							Text("Assets complete.")
						}
					} footer: {
						Text("Version \(assets.version.version)")
							.foregroundStyle(.secondary)
							.font(.callout)
					}
					
					Section {
						AsyncButton("Reset") {
							await assetManager.reset()
							imageManager.clear()
						}
					} header: {
						Text("Repair")
					} footer: {
						Text("In case something went wrong, use this button to force a full refetch of the assets and images.")
					}
				}
			} else {
				VStack(alignment: .leading) {
					Text("Missing assets!")
						.font(.headline)
					Text("Anything with images will not display correctly.")
				}
				
				Section {
					AsyncButton("Download Assets Now") {
						await assetManager.loadAssets()
					}
				} header: {
					Text("Repair")
				} footer: {
					Text("Assets should be fetched automatically, but in case something went wrong, feel free to initiate the process manually.")
				}
			}
		}
		.navigationTitle("Assets")
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
struct AssetsInfoView_Previews: PreviewProvider {
    static var previews: some View {
		AssetsInfoView(assetManager: .forPreviews)
		AssetsInfoView(assetManager: .mockEmpty)
    }
}
#endif
