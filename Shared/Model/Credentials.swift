import Foundation
import UserDefault
import KeychainSwift
import ValorantAPI

private let keychain = KeychainSwift()

final class CredentialsStorage: ObservableObject {
	@UserDefault("username") private static var storedUsername = ""
	@UserDefault("region") private static var storedRegion = Region.europe
	
	@Published var username = storedUsername {
		didSet { Self.storedUsername = username }
	}
	
	@Published var password = keychain.get("password") ?? "" {
		didSet { keychain.set(password, forKey: "password") }
	}
	
	@Published var region = storedRegion {
		didSet { Self.storedRegion = region }
	}
	
	init() {}
}

extension Region: DefaultsValueConvertible {
	public typealias DefaultsRepresentation = RawValue
}
