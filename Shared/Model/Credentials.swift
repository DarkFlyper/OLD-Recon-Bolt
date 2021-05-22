import Foundation
import UserDefault
import KeychainSwift
import ValorantAPI

protocol Keychain {
	func get(_ key: String) -> String?
	@discardableResult
	func set(_ value: String, forKey key: String) -> Bool
}

extension KeychainSwift: Keychain {
	func set(_ value: String, forKey key: String) -> Bool {
		set(value, forKey: key, withAccess: nil)
	}
}

struct MockKeychain: Keychain {
	func get(_ key: String) -> String? { nil }
	func set(_ value: String, forKey key: String) -> Bool { false }
}

final class CredentialsStorage: ObservableObject {
	@UserDefault("username") private static var storedUsername = ""
	@UserDefault("region") private static var storedRegion = Region.europe
	
	@Published var username = storedUsername {
		didSet { Self.storedUsername = username }
	}
	
	@Published var password = "" {
		didSet { keychain.set(password, forKey: "password") }
	}
	
	@Published var region = storedRegion {
		didSet { Self.storedRegion = region }
	}
	
	private let keychain: Keychain
	
	init(keychain: Keychain) {
		self.keychain = keychain
		if let stored = keychain.get("password") {
			password = stored
		}
	}
}

extension Region: DefaultsValueConvertible {
	public typealias DefaultsRepresentation = RawValue
}
