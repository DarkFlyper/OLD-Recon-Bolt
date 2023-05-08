import Foundation
import CryptoKit
import Algorithms

#if canImport(ValorantAPI)
import ValorantAPI

struct Denylist {
	static let entries: [SaltedHash] = [
		.init(salt: "6d64ee0a13d65ca4e1edeff8c73528c8", hash: "15a3b029f09d7041312cc8c3ceb090d5230f23a290c8747fb7dff4d29add703f"),
	]
	
	static func allows(_ id: Player.ID) -> Bool {
		let raw = id.rawID.description.data(using: .utf8)!
		return !entries.contains { $0.matches(raw) }
	}
}
#endif

extension Sequence<UInt8> {
	func hexEncoded() -> String {
		self.lazy.map { String(format: "%02hhx", $0) }.joined()
	}
}

extension Data {
	init(hexEncoded hex: String) {
		self.init(hex.chunks(ofCount: 2).lazy.map { UInt8($0, radix: 16)! })
	}
}

struct SaltedHash: CustomStringConvertible {
	var salt: Data
	var hash: Data
	
	var description: String {
		#"SaltedHash(salt: "\#(salt.hexEncoded())", hash: "\#(hash.hexEncoded())")"#
	}
	
	func matches(bytesOf string: some StringProtocol) -> Bool {
		matches(string.data(using: .utf8)!)
	}
	
	func matches(_ data: some DataProtocol) -> Bool {
		var hasher = SHA256()
		hasher.update(data: data)
		hasher.update(data: salt)
		return hash.elementsEqual(hasher.finalize())
	}
}

extension SaltedHash {
	init(salting string: some StringProtocol) {
		self.init(salting: string.data(using: .utf8)!)
	}
	
	init(salting data: some DataProtocol) {
		var hasher = SHA256()
		hasher.update(data: data)
		
		self.salt = Data((1...16).map { _ in UInt8.random(in: .min ... .max) })
		hasher.update(data: salt)
		
		self.hash = Data(hasher.finalize())
	}
	
	init(salt: String, hash: String) {
		self.init(
			salt: .init(hexEncoded: salt),
			hash: .init(hexEncoded: hash)
		)
	}
}
