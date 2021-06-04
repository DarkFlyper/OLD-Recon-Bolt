import Foundation
import UserDefault
import KeychainSwift
import ValorantAPI

struct Credentials: Codable {
	var region = Region.europe
	var username = ""
	var password = ""
	
	init() {}
	
	init?(from keychain: Keychain) {
		guard let stored = keychain["credentials"] else { return nil }
		do {
			self = try JSONDecoder().decode(Self.self, from: stored)
		} catch {
			print("could not decode stored credentials!")
			dump(error)
			print()
			return nil
		}
	}
	
	func save(to keychain: Keychain) {
		keychain["credentials"] = try! JSONEncoder().encode(self)
	}
}

protocol Keychain {
	subscript(key: String) -> Data? { get nonmutating set }
}

extension KeychainSwift: Keychain {
	subscript(key: String) -> Data? {
		get { getData(key) }
		set {
			if let newValue = newValue {
				if !set(newValue, forKey: key) {
					print("Could not store value to keychain for key \(key)!")
				}
			} else {
				delete(key)
			}
		}
	}
}

struct MockKeychain: Keychain {
	subscript(key: String) -> Data? {
		get { nil }
		nonmutating set {}
	}
}
