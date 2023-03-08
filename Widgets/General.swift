import SwiftUI

enum Managers {
	@MainActor static let accounts = AccountManager()
	@MainActor static let assets = AssetManager()
	// TODO: this storage should really be shared with the main app somehow…
	@MainActor static let images = ImageManager()
}

extension AssetImage {
	func resolved() async -> Image? {
		if let existing = AssetImage.preloaded[self] {
			return existing
		} else {
			return await Managers.images.awaitImage(for: self).map(Image.init)
		}
	}
	
	func preload() async {
		AssetImage.preloaded[self] = await resolved()
	}
}

extension Sequence {
	func concurrentMap<T>(_ transform: (Element) async throws -> T) async throws -> [T] {
		try await withoutActuallyEscaping(transform) { transform in
			try await withThrowingTaskGroup(of: (Int, T).self) { group in
				var count = 0
				for (i, element) in self.enumerated() {
					count += 1
					group.addTask {
						(i, try await transform(element))
					}
				}
				
				// maintain order
				var transformed: [T?] = .init(repeating: nil, count: count)
				for try await (i, newElement) in group {
					transformed[i] = newElement
				}
				return transformed.map { $0! }
			}
		}
	}
	
	func concurrentMap<T>(_ transform: (Element) async -> T) async -> [T] {
		await withoutActuallyEscaping(transform) { transform in
			await withTaskGroup(of: (Int, T).self) { group in
				var count = 0
				for (i, element) in self.enumerated() {
					count += 1
					group.addTask {
						(i, await transform(element))
					}
				}
				
				// maintain order
				var transformed: [T?] = .init(repeating: nil, count: count)
				for await (i, newElement) in group {
					transformed[i] = newElement
				}
				return transformed.map { $0! }
			}
		}
	}
}
