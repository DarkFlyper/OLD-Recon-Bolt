import SwiftUI
import ValorantAPI
import UserDefault

@MainActor
final class GameConfigManager: ObservableObject {
	@Published
	private var stored = Storage.stored {
		didSet { Storage.stored = stored }
	}
	
	private var inProgress: Set<Location> = []
	private let updateInterval: TimeInterval = 24 * 3600
	
	func config(for location: Location) -> GameConfig? {
		stored.configs[location]?.config
	}
	
	#if !WIDGETS
	fileprivate func autoUpdate(for location: Location, using load: @escaping ValorantLoadFunction) {
		if let entry = stored.configs[location], -entry.lastUpdate.timeIntervalSinceNow < updateInterval { return }
		guard inProgress.insert(location).inserted else { return }
		Task {
			await load { [self] client in
				do {
					let config = try await client.getGameConfig()
					store(config, for: location)
				} catch {
					print("error updating game config for \(location):", error)
				}
				inProgress.remove(location)
			}
		}
	}
	#endif
	
	private func store(_ config: GameConfig, for location: Location) {
		stored.configs[location] = .init(lastUpdate: .now, config: config)
	}
	
	private struct StoredConfigs: Codable, DefaultsValueConvertible {
		var configs: [Location: Entry] = [:]
		
		struct Entry: Codable {
			var lastUpdate: Date
			var config: GameConfig
		}
	}
	
	private enum Storage {
		@UserDefault("GameConfigManager.stored", defaults: .shared)
		static var stored: StoredConfigs = .init()
	}
}

/// provides access to the current location's config without repetition and immediately (vs a late-initialized solution) thanks to nested property wrappers
@propertyWrapper
struct CurrentGameConfig: DynamicProperty {
	@EnvironmentObject private var manager: GameConfigManager
	@Environment(\.assets) private var assets
	@Environment(\.location) private var location
	
	var projectedValue: Self { self }
	
	var seasons: SeasonCollection.Accessor? {
		guard let wrappedValue else { return nil }
		return assets?.seasons.with(wrappedValue)
	}
	
	init() {}
	
#if WIDGETS
	var wrappedValue: GameConfig? {
		guard let location else { return nil }
		return manager.config(for: location)
	}
#else
	@Environment(\.valorantLoad) private var load
	@StateObject private var storage = Storage()
	
	var wrappedValue: GameConfig? {
		guard let location else { return nil }
#if DEBUG
		guard !isInSwiftUIPreview else { return PreviewData.gameConfig }
#endif
		if !storage.hasFetched {
			manager.autoUpdate(for: location, using: load)
		}
		return manager.config(for: location)
	}
	
	private final class Storage: ObservableObject {
		var hasFetched = false // no need for updates, just need this to persist
	}
#endif
}

extension EnvironmentValues {
	var location: Location? {
		get { self[LocationKey.self] ?? (isInSwiftUIPreview ? .europe : nil) }
		set { self[LocationKey.self] = newValue }
	}
	
	private enum LocationKey: EnvironmentKey {
		static let defaultValue: Location? = nil
	}
}
