import SwiftUI
import ValorantAPI
import UserDefault

@MainActor
final class GameConfigManager: ObservableObject {
	@Published
	// got intractable errors when trying to compose these naively
	private var _stored = UserDefault(wrappedValue: StoredConfigs(), "GameConfigManager.stored", defaults: .shared)
	
	private var stored: StoredConfigs {
		get { _stored.wrappedValue }
		set { _stored.wrappedValue = newValue }
	}
	
	private var inProgress: Set<Location> = []
	private let updateInterval: TimeInterval = 24 * 3600
	
	func config(for location: Location) -> GameConfig? {
		stored.configs[location]?.config
	}
	
	func configs() -> [Location: GameConfig] {
		stored.configs.mapValues(\.config)
	}
	
	func autoUpdate(for location: Location, using client: ValorantClient) async {
		if let entry = stored.configs[location], -entry.lastUpdate.timeIntervalSinceNow < updateInterval { return }
		guard inProgress.insert(location).inserted else { return }
		defer { inProgress.remove(location) }
		do {
			let config = try await client.getGameConfig()
			stored.configs[location] = .init(lastUpdate: .now, config: config)
		} catch {
			print("error updating game config for \(location):", error)
		}
	}
	
	private struct StoredConfigs: Codable, DefaultsValueConvertible {
		var configs: [Location: Entry] = [:]
		
		struct Entry: Codable {
			var lastUpdate: Date
			var config: GameConfig
		}
	}
}

#if !WIDGETS
private struct GameConfigUpdater: ViewModifier {
	@EnvironmentObject private var manager: GameConfigManager
	@Environment(\.assets) private var assets
	@Environment(\.location) private var location
	
	func body(content: Content) -> some View {
		content
			.font(nil)
			.valorantLoadTask(id: location) {
				guard let location else { return }
				await manager.autoUpdate(for: location, using: $0)
			}
	}
}

extension View {
	func updatingGameConfig() -> some View {
		modifier(GameConfigUpdater())
	}
}
#endif

extension EnvironmentValues {
	var location: Location? {
		get { self[LocationKey.self] ?? (isInSwiftUIPreview ? .europe : nil) }
		set { self[LocationKey.self] = newValue }
	}
	
	private enum LocationKey: EnvironmentKey {
		static let defaultValue: Location? = nil
	}
	
	var seasons: SeasonCollection.Accessor? {
		config.flatMap { assets?.seasons.with($0) }
	}
	
	var config: GameConfig? {
		guard let location else { return nil }
		let config = self[ConfigsKey.self]?[location]
#if DEBUG
		return config ?? (isInSwiftUIPreview ? PreviewData.gameConfig : nil)
#else
		return config
#endif
	}
	
	var configs: [Location: GameConfig]? {
		get { self[ConfigsKey.self] }
		set { self[ConfigsKey.self] = newValue }
	}
	
	private enum ConfigsKey: EnvironmentKey {
		#if WIDGETS
		@MainActor // this is safe right?
		static let defaultValue: [Location: GameConfig]? = GameConfigManager().configs()
		#else
		static let defaultValue: [Location: GameConfig]? = nil
		#endif
	}
}
