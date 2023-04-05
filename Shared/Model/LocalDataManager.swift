import Foundation
import Combine
import HandyOperators

typealias LocalDataPublisher<Value> = AnyPublisher<(value: Value, wasCached: Bool), Never>

/// - "mom can we have a database?"
/// - "no honey we have a database at home"
/// - database at home:
@MainActor
final class LocalDataManager<Object: Identifiable & Codable> where Object.ID: LosslessStringConvertible {
	private typealias Subject = PassthroughSubject<Object, Never>
	
	// not @Published so we have manual control, avoiding many publishes when working in bulk
	private var cache: [Object.ID: Entry?] = [:] // nil values represent that we've confirmed there's no cache file
	private var subjects: [Object.ID: Subject] = [:]
	private let storage: Storage
	
	nonisolated let folderURL: URL
	/// When the object was last updated longer ago than this, it is automatically updated on next fetch.
	let ageCausingAutoUpdate: TimeInterval?
	
	nonisolated init(localPath: String = "\(Object.self)", ageCausingAutoUpdate: TimeInterval? = nil) {
		self.folderURL = FolderLocations.localData.appendingPathComponent(localPath) <- {
			try? FileManager.default.createDirectory(
				at: $0,
				withIntermediateDirectories: true,
				attributes: nil
			)
		}
		self.ageCausingAutoUpdate = ageCausingAutoUpdate
		self.storage = .init(folderURL: folderURL)
	}
	
	func store<S: Sequence>(_ objects: S, asOf updateTime: Date) where S.Element == Object {
		for object in objects {
			store(object, asOf: updateTime)
		}
	}
	
	func store(_ object: Object, asOf updateTime: Date) {
		let entry = Entry(lastUpdate: updateTime, object: object)
		let existing = cache[object.id] ?? nil
		if let existing, existing.lastUpdate > updateTime { return }
		
		cache[object.id] = entry
		subjects[object.id]?.send(object)
		
		Task.detached(priority: .utility) { [storage] in
			await storage.trySave(entry)
		}
	}
	
	func loadedObject(for id: Object.ID) -> Object? {
		cache[id]??.object
	}
	
	private func cachedEntry(for id: Object.ID) async -> Entry? {
		if let cached = cache[id] {
			return cached
		} else {
			return await storage.tryLoadEntry(with: id) <- { cache[id] = $0 }
		}
	}
	
	private func cachedEntries(for ids: Set<Object.ID>) async -> [Entry] {
		let loaded = ids.compactMap { cache[$0] }
		let notLoadedIDs = ids.subtracting(ids.lazy.filter(cache.keys.contains(_:)))
		let notLoaded: [Object.ID: Entry] = .init(
			values: await storage.tryLoadEntries(with: notLoadedIDs)
		)
		for id in notLoadedIDs {
			cache[id] = notLoaded[id]
		}
		return loaded.compactMap { $0 } + notLoaded.values
	}
	
	func cachedObject(for id: Object.ID) async -> Object? {
		await cachedEntry(for: id)?.object
	}
	
	func cachedObjects(for ids: some Sequence<Object.ID>) async -> [Object] {
		await cachedEntries(for: Set(ids)).map(\.object)
	}
	
	nonisolated func objectPublisher(for id: Object.ID) -> LocalDataPublisher<Object> {
		Future { promise in
			Task {
				promise(.success(await self._objectPublisher(for: id)))
			}
		}
		.flatMap { $0 }
		.eraseToAnyPublisher()
	}
	
	private func _objectPublisher(for id: Object.ID) async -> LocalDataPublisher<Object> {
		await cachedObject(for: id).publisher.map { (value: $0, wasCached: true) }
			.merge(with: subject(for: id).map { (value: $0, wasCached: false) })
			.eraseToAnyPublisher()
	}
	
	private func subject(for id: Object.ID) -> Subject {
		subjects[id] ?? (.init() <- { subjects[id] = $0 })
	}
	
	private var inProgressUpdates: Set<Object.ID> = []
	
	func autoUpdateObject(for id: Object.ID, update: (Object?) async throws -> Object) async throws {
		let cached = await cachedEntry(for: id)
		if let cached, !shouldAutoUpdate(cached) {
			return // nothing to do
		}
		
		guard inProgressUpdates.insert(id).inserted else { return }
		defer { inProgressUpdates.remove(id) }
		
		// auto-update necessary
		try await tryLoad {
			try await update(cached?.object) <- { store($0, asOf: .now) }
		}
	}
	
	func fetchIfNecessary(for id: Object.ID, fetch: (Object.ID) async throws -> Object) async throws {
		try await autoUpdateObject(for: id) { _ in try await fetch(id) }
	}
	
	func fetchIfNecessary(_ ids: [Object.ID], fetch: ([Object.ID]) async throws -> [Object]) async throws {
		let cached = await cachedEntries(for: Set(ids))
		guard cached.count < ids.count || cached.contains(where: shouldAutoUpdate) else { return }
		try await fetch(ids) <- { store($0, asOf: .now) }
	}
	
	@discardableResult
	private nonisolated func tryLoad<T>(load: () async throws -> T) async throws -> T? {
		do {
			return try await load()
		} catch let error as URLError {
			// error loading data: assume offline
			dump(error)
			return nil
		}
	}
	
	private nonisolated func shouldAutoUpdate(_ entry: Entry) -> Bool {
		guard let threshold = ageCausingAutoUpdate else { return false }
		return -entry.lastUpdate.timeIntervalSinceNow > threshold
	}
	
	struct DiskUsage {
		var tally: [Object.ID: Int64] = [:]
		var unaccountedFor: Int64 = 0
		var unknownIDs: Set<Object.ID> = []
	}
	
	struct Entry: Codable, Identifiable {
		var lastUpdate = Date()
		var object: Object
		
		var id: Object.ID { object.id }
	}
	
	final actor Storage {
		let folderURL: URL
		
		init(folderURL: URL) {
			self.folderURL = folderURL
		}
		
		private nonisolated func fileURL(for id: Object.ID) -> URL {
			folderURL.appendingPathComponent("\(id.description).json")
		}
		
		func trySave(_ entry: Entry) {
			do {
				try save(entry)
			} catch {
				print("error saving \(entry) to disk: \(error)")
				dump(error)
			}
		}
		
		func tryLoadEntries(with ids: any Sequence<Object.ID>) -> [Entry] {
			ids.compactMap(tryLoadEntry(with:))
		}
		
		func tryLoadEntry(with id: Object.ID) -> Entry? {
			do {
				return try loadEntry(with: id)
			} catch {
				print("error loading entry with id \(id) from disk: \(error)")
				dump(error)
				return nil
			}
		}
		
		private func loadEntry(with id: Object.ID) throws -> Entry? {
			let url = fileURL(for: id)
			guard FileManager.default.fileExists(atPath: url.path) else { return nil }
			let data = try Data(contentsOf: url)
			return try decoder.decode(Entry.self, from: data)
		}
		
		private func save(_ entry: Entry) throws {
			let raw = try encoder.encode(entry)
			let url = fileURL(for: entry.id)
			try raw.write(to: url, options: .atomic)
		}
	}
}

extension LocalDataManager {
	func diskUsage(for ids: some Sequence<Object.ID>) async throws -> DiskUsage {
		try await storage.diskUsage(for: ids)
	}
	
	func clearOut(idFilter: Set<Object.ID>? = nil) async throws {
		try await storage.clearOut(idFilter: idFilter)
		
		if let idFilter {
			for id in idFilter {
				cache.removeValue(forKey: id)
			}
		} else {
			cache = [:]
		}
	}
}

extension LocalDataManager.Storage {
	func diskUsage(for ids: some Sequence<Object.ID>) throws -> LocalDataManager.DiskUsage {
		let files = try FileManager.default.contentsOfDirectory(
			at: folderURL,
			includingPropertiesForKeys: [.fileSizeKey]
		)
		let knownIDs = Set(ids)
		return .init() <- { usage in
			for file in files {
				guard let id = Object.ID(file.deletingPathExtension().lastPathComponent) else { continue }
				let size = try! Int64(file.resourceValues(forKeys: [.fileSizeKey]).fileSize!)
				if knownIDs.contains(id) {
					usage.tally[id, default: 0] += size
				} else {
					usage.unaccountedFor += size
					usage.unknownIDs.insert(id)
				}
			}
		}
	}
	
	func clearOut(idFilter: Set<Object.ID>?) throws {
		let files = try FileManager.default.contentsOfDirectory(
			at: folderURL,
			includingPropertiesForKeys: []
		)
		if let idFilter {
			for file in files {
				guard
					let id = Object.ID(file.deletingPathExtension().lastPathComponent),
					idFilter.contains(id)
				else { continue }
				try FileManager.default.removeItem(at: file)
			}
		} else {
			for file in files {
				try FileManager.default.removeItem(at: file)
			}
		}
	}
}

private let decoder = JSONDecoder()
private let encoder = JSONEncoder()

extension TimeInterval {
	static func minutes(_ minutes: Double) -> Self {
		minutes * 60
	}
	
	static func hours(_ hours: Double) -> Self {
		minutes(hours * 60)
	}
}
