import Foundation
import UserDefault
import KeychainSwift

private let keychain = KeychainSwift()

final class CredentialsStorage: ObservableObject {
	@UserDefault("username") private static var storedUsername = ""
	
	@Published var username = storedUsername {
		didSet { Self.storedUsername = username }
	}
	
	@Published var password = keychain.get("password") ?? "" {
		didSet { keychain.set(password, forKey: "password") }
	}
	
	init() {}
}
