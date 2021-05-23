import Foundation
import ValorantAPI
import UserDefault
import Combine
import SwiftUI

final class AssetManager: ObservableObject {
	typealias BasicPublisher = AssetClient.BasicPublisher
	
	@Published private(set) var assets: AssetCollection?
	@Published private(set) var progress: AssetDownloadProgress?
	@Published private(set) var error: Error?
	private var loadTask: AnyCancellable?
	
	init() {
		loadTask = Self
			.loadAssets() { progress in
				DispatchQueue.main.async {
					print(progress)
					self.progress = progress
				}
			}
			.receive(on: DispatchQueue.main)
			.sinkResult { self.assets = $0 }
				onFailure: { self.error = $0 }
				always: { self.progress = nil }
	}
	
	static let forPreviews = AssetManager(assets: stored)
	
	private init(assets: AssetCollection?) {
		self.assets = assets
	}
	
	static func loadAssets(
		forceUpdate: Bool = false,
		onProgress: AssetProgressCallback? = nil
	) -> BasicPublisher<AssetCollection> {
		client.getCurrentVersion()
			.flatMap { [client] version -> BasicPublisher<AssetCollection> in
				if !forceUpdate, let stored = stored, stored.version == version {
					return Just(stored)
						.setFailureType(to: Error.self)
						.eraseToAnyPublisher()
				} else {
					return client
						.collectAssets(for: version, onProgress: onProgress)
						.also { Self.stored = $0 }
						.eraseToAnyPublisher()
				}
			}
			.eraseToAnyPublisher()
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
