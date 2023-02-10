import Foundation
import KeychainSwift
import HandyOperators

protocol Keychain {
	subscript(key: String) -> Data? { get nonmutating set }
}

extension Keychain where Self == KeychainSwift {
	static var standard: Self { .instance }
}

extension KeychainSwift: Keychain {
	static let instance = KeychainSwift() <- {
		$0.accessGroup = "V2EPDFA9PV.com.juliand665.Valorant-Viewer"
	}
	
	subscript(key: String) -> Data? {
		get { getData(key) }
		set {
			if let newValue {
				let oldValue = getData(key)
				if !set(newValue, forKey: key) {
					print("Could not store value to keychain for key \(key)!")
					// attempt to restore…
					if let oldValue {
						set(oldValue, forKey: key)
					}
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
