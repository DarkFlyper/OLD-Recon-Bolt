import SwiftUI

struct AssetsInfoView: View {
	@ObservedObject var assetManager: AssetManager
	@State var newestVersion: AssetVersion?
	
	@EnvironmentObject private var imageManager: ImageManager
	
	var body: some View {
		List {
			if let error = assetManager.error {
				errorContent(for: error)
			} else if let assets = assetManager.assets {
				if let newestVersion, assets.version != newestVersion {
					outdatedContent(assets: assets, newestVersion: newestVersion)
				} else {
					standardContent(assets: assets)
				}
			} else {
				missingAssetsContent()
			}
			
			NavigationLink {
				LanguagePicker(languageOverride: assetManager.languageOverride) { language in
					await assetManager.setLanguageOverride(to: language)
				}
			} label: {
				HStack {
					Text("Language", comment: "Asset Management: this row shows the language of the current assets")
					Spacer()
					LanguageOverrideLabel(language: assetManager.languageOverride)
						.foregroundColor(.secondary)
				}
			}
		}
		.navigationTitle("Assets")
		.task {
			do {
				newestVersion = try await AssetClient(language: "en-US").getCurrentVersion()
			} catch {
				print("could not fetch newest assets version:", error)
			}
		}
	}
	
	@ViewBuilder
	func standardContent(assets: AssetCollection) -> some View {
		Section {
			if newestVersion != nil {
				Text("Assets up to date!", comment: "Asset Management")
					.font(.headline)
			} else {
				Text("Assets complete.", comment: "Asset Management: shown before the newest version is fetched, so it's not know yet if the assets are up to date or outdated")
			}
			
			HStack {
				Text("Version", comment: "Asset Management: this row shows the version of the current assets")
				Spacer()
				Text(assets.version.version)
					.foregroundColor(.secondary)
			}
		}
		
		Section {
			AsyncButton {
				await assetManager.reset()
				imageManager.clear()
			} label: {
				Text("Reset", comment: "Asset Management: button")
			}
		} header: {
			Text("Repair", comment: "Asset Management: section")
		} footer: {
			Text("In case something went wrong, use this button to force a full refetch of the assets and images.", comment: "Asset Management")
		}
	}
	
	@ViewBuilder
	func outdatedContent(assets: AssetCollection, newestVersion: AssetVersion) -> some View {
		VStack(alignment: .leading) {
			Text("Assets out of date!", comment: "Asset Management")
				.font(.headline)
			
			VStack(alignment: .trailing) {
				Text("Current version: \(assets.version.version)", comment: "Asset Management")
				Text("Newest available: \(newestVersion.version)", comment: "Asset Management")
			}
			.foregroundStyle(.secondary)
			.font(.callout.monospacedDigit())
		}
		
		Section {
			AsyncButton {
				await assetManager.tryLoadAssets()
			} label: {
				Text("Update Now", comment: "Asset Management: button")
			}
		} header: {
			Text("Repair", comment: "Asset Management: section")
		} footer: {
			Text("Assets should be fetched automatically, but in case something went wrong, feel free to initiate the process manually.")
		}
	}
	
	@ViewBuilder
	func missingAssetsContent() -> some View {
		VStack(alignment: .leading) {
			Text("Missing assets!", comment: "Asset Management")
				.font(.headline)
			Text("Anything with images will not display correctly.", comment: "Asset Management")
		}
		
		Section {
			AsyncButton("Download Assets Now") {
				await assetManager.tryLoadAssets()
			}
		} header: {
			Text("Repair", comment: "Asset Management: section")
		} footer: {
			Text("Assets should be fetched automatically, but in case something went wrong, feel free to initiate the process manually.")
		}
	}
	
	@ViewBuilder
	func errorContent(for error: Error) -> some View {
		Text("Error downloading assets!", comment: "Asset Management")
			.font(.headline)
		
		Text(String(describing: error))
			.font(.caption)
		
		AsyncButton("Retry") { await assetManager.tryLoadAssets() }
	}
	
	struct LanguagePicker: View {
		var languageOverride: String?
		var select: (String?) async -> Void
		
		var body: some View {
			List {
				Section {
					cell(forLanguage: nil)
				}
				Section {
					ForEach(Locale.valorantLanguages, id: \.self) { language in
						cell(forLanguage: language)
					}
				}
			}
			.navigationTitle(Text("Select Language", comment: "Asset Management: language picker title"))
			.navigationBarTitleDisplayMode(.inline)
		}
		
		func cell(forLanguage language: String?) -> some View {
			AsyncButton {
				await select(language)
			} label: {
				HStack {
					LanguageOverrideLabel(language: language)
						.tint(.primary)
					Spacer()
					Image(systemName: "checkmark")
						.opacity(language == languageOverride ? 1 : 0)
				}
			}
		}
	}
	
	struct LanguageOverrideLabel: View {
		let language: String?
		
		var body: some View {
			if let language {
				Text(Locale.current.localizedString(forIdentifier: language) ?? language)
			} else {
				Text("Match App Language", comment: "Asset Management: option to match assets language to app language")
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
