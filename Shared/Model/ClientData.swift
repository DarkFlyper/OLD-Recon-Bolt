import Foundation
import ValorantAPI
import UserDefault
import HandyOperators

protocol ClientData {
	var user: User { get }
	var client: ValorantClient { get }
	
	static func authenticated(using credentials: Credentials) async throws -> Self
	func reauthenticated() async throws -> Self
	
	init?(using keychain: Keychain)
	func save(using keychain: Keychain)
}

extension ClientData {
	var id: Player.ID { user.id }
}

final class ClientDataStore: ObservableObject {
	let keychain: Keychain
	@Published var data: ClientData? {
		didSet { data?.save(using: keychain) }
	}
	
	init<StoredData: ClientData>(keychain: Keychain, for _: StoredData.Type) {
		self.keychain = keychain
		self.data = StoredData(using: keychain)
	}
}

struct StandardClientData: ClientData {
	var user: User { client.user }
	
	var client: ValorantClient
	
	private var credentials: Credentials
	
	@UserDefault("ClientData.stored")
	private static var stored: ValorantClient?
	
	static func authenticated(using credentials: Credentials) async throws -> Self {
		let client = try await ValorantClient.authenticated(
			username: credentials.username,
			password: credentials.password,
			region: credentials.region
		)
		return Self(client: client, credentials: credentials)
	}
	
	init?(using keychain: Keychain) {
		guard
			let credentials = Credentials(from: keychain),
			let stored = Self.stored
		else { return nil }
		
		self.client = stored
		self.credentials = credentials
	}
	
	fileprivate init(client: ValorantClient, credentials: Credentials) {
		self.client = client
		self.credentials = credentials
	}
	
	func save(using keychain: Keychain) {
		credentials.save(to: keychain)
		Self.stored = client
	}
	
	func reauthenticated() async throws -> Self {
		try await Self.authenticated(using: credentials)
	}
}

extension ValorantClient: DefaultsValueConvertible {}
