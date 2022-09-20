import Foundation
import KeychainSwift

protocol Keychain {
	subscript(key: String) -> Data? { get nonmutating set }
}

extension Keychain where Self == KeychainSwift {
	static var standard: Self { .init() }
}

extension KeychainSwift: Keychain {
	subscript(key: String) -> Data? {
		get { getData(key) }
		set {
			if let newValue {
				if !set(newValue, forKey: key) {
					print("Could not store value to keychain for key \(key)!")
				}
			} else {
				delete(key)
			}
		}
	}
}

#if DEBUG
struct MockKeychain: Keychain {
	subscript(key: String) -> Data? {
		get { nil }
		nonmutating set {}
	}
}
#endif
