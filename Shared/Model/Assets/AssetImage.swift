import Foundation
import SwiftUI
import Combine
import Protoquest
import HandyOperators

struct AssetImage: Hashable {
	var url: URL
	
	var image: Image {
		imageIfLoaded ?? Image(systemName: "x")
	}
	
	var imageIfLoaded: Image? {
		struct LoadingError: Error {}
		
		do {
			return try imageCache.getValue(forKey: localURL) {
				try Image(at: $0) ??? LoadingError()
			}
		} catch {
			print("error loading image from \(url) stored at \(localURL):")
			dump(error)
			return nil
		}
	}
	
	var localURL: URL {
		Self.baseURL.appendingPathComponent(url.path, isDirectory: false)
	}
	
	private static let baseURL = try! FileManager.default.url(
		for: .cachesDirectory,
		in: .userDomainMask,
		appropriateFor: nil,
		create: true
	)
}

private let imageCache = Cache<URL, Image>()

final class Cache<Key: Hashable, Value> {
	private var cached: [Key: Value] = [:]
	
	func invalidateValue(forKey key: Key) {
		cached[key] = nil
	}
	
	func getValue(forKey key: Key, compute: (Key) throws -> Value) rethrows -> Value {
		try cached[key] ?? (compute(key) <- { cached[key] = $0 })
	}
}

extension AssetClient {
	func download(_ image: AssetImage) -> BasicPublisher<Void> {
		send(ImageDownloadRequest(imageURL: image.url))
			.tryMap {
				try FileManager.default.createDirectory(
					at: image.localURL.deletingLastPathComponent(),
					withIntermediateDirectories: true
				)
				try $0.write(to: image.localURL)
			}
			.eraseToAnyPublisher()
	}
}

private struct ImageDownloadRequest: GetDataRequest {
	var imageURL: URL
	
	var baseURLOverride: URL? {
		imageURL
	}
}

extension AssetImage: Codable {
	init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		url = try container.decode(URL.self)
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(url)
	}
}
