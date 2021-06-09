import Foundation
import ValorantAPI
import UserDefault
import SwiftUI
import HandyOperators

final class AssetManager: ObservableObject {
	// TODO: shouldn't this be implicit on @Published properties?
	@MainActor
	@Published private(set) var assets: AssetCollection?
	@MainActor
	@Published private(set) var progress: AssetDownloadProgress?
	@MainActor
	@Published private(set) var error: Error?
	
	init() {
		_assets = .init(wrappedValue: Self.stored)
		async { await loadAssets() }
	}
	
	@MainActor
	func loadAssets() async {
		guard progress == nil else { return }
		
		do {
			assets = try await Self.loadAssets() { progress in
				DispatchQueue.main.async {
					print(progress)
					self.progress = progress
				}
			}
		} catch {
			self.error = error
		}
		
		self.progress = nil
	}
	
	#if DEBUG
	static let forPreviews = AssetManager(assets: stored)
	static let mockEmpty = AssetManager(assets: nil)
	
	private init(assets: AssetCollection?) {
		_assets = .init(wrappedValue: assets)
	}
	
	static let mockDownloading = AssetManager(mockProgress: .init(completed: 42, total: 69))
	
	private init(mockProgress: AssetDownloadProgress?) {
		_progress = .init(wrappedValue: mockProgress)
	}
	#endif
	
	static func loadAssets(
		forceUpdate: Bool = false,
		onProgress: AssetProgressCallback? = nil
	) async throws -> AssetCollection {
		let version = try await client.getCurrentVersion()
		if !forceUpdate, let stored = stored, stored.version == version {
			return stored
		} else {
			return try await client
				.collectAssets(for: version, onProgress: onProgress)
			<- { Self.stored = $0 }
		}
	}
	
	@UserDefault("AssetManager.stored")
	fileprivate static var stored: AssetCollection?
	
	private static let client = AssetClient()
}

struct AssetCollection: Codable {
	let version: AssetVersion
	
	let maps: [MapID: MapInfo]
	let agents: [Agent.ID: AgentInfo]
	let missions: [MissionInfo.ID: MissionInfo]
	let objectives: [ObjectiveInfo.ID: ObjectiveInfo]
	
	var images: Set<AssetImage> {
		Set(maps.values.flatMap(\.images) + agents.values.flatMap(\.images))
	}
}

extension AssetCollection: DefaultsValueConvertible {}

struct AssetManager_Previews: PreviewProvider {
	static var previews: some View {
		PreviewView()
	}
	
	private struct PreviewView: View {
		@StateObject var manager = AssetManager()
		
		var body: some View {
			VStack(spacing: 10) {
				Text(verbatim: "stored: \(AssetManager.stored as Any)")
					.lineLimit(10)
				Text(verbatim: "\(manager.progress?.description ?? "nothing in progress")")
			}
			.padding()
			.previewLayout(.sizeThatFits)
		}
	}
}
