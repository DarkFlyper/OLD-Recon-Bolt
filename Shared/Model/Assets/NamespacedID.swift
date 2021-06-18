import Foundation
import ValorantAPI

protocol NamespacedID: _RawWrapper, Hashable, Codable where RawValue == String {
	static var namespace: String { get }
	
	init(rawValue: String)
}

extension NamespacedID {
	init(_ rawValue: RawValue) {
		self.init(rawValue: rawValue)
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let raw = try container.decode(String.self)
		let junk = "\(Self.namespace)::"
		self.init(
			raw.hasPrefix(junk)
				? String(raw.dropFirst(junk.count))
				: raw
		)
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(rawValue)
	}
}
