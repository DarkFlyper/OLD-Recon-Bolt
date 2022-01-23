import Foundation
import ValorantAPI
import UserDefault
import HandyOperators

protocol ClientData {
	var userID: User.ID { get }
	var client: ValorantClient { get }
	
	static func authenticated(using credentials: Credentials) async throws -> Self
	func reauthenticated() async throws -> Self
	
	init?(using keychain: Keychain)
	func save(using keychain: Keychain) async
}

extension ClientData {
	var userID: User.ID { client.userID }
}

final class ClientDataStore: ObservableObject {
	let keychain: Keychain
	@Published var data: ClientData? {
		didSet {
			// this won't catch when the client reestablishes its session from cookies, but the token only lasts an hour anyway, during which time recon bolt will likely keep running, so it's not worth storing to defaults.
			Task { await data?.save(using: keychain) }
		}
	}
	
	init<StoredData: ClientData>(keychain: Keychain, for _: StoredData.Type) {
		self.keychain = keychain
		self.data = StoredData(using: keychain)
	}
}

struct StandardClientData: ClientData {
	var client: ValorantClient
	
	private var credentials: Credentials
	
	@UserDefault("ClientData.stored")
	private static var stored: ValorantClient.SavedData?
	
	static func authenticated(using credentials: Credentials) async throws -> Self {
		let client = try await ValorantClient.authenticated(
			username: credentials.username,
			password: credentials.password,
			location: credentials.location
		)
		return Self(client: client, credentials: credentials)
	}
	
	init?(using keychain: Keychain) {
		guard
			let credentials = Credentials(from: keychain),
			let stored = Self.stored
		else { return nil }
		
		self.client = .init(from: stored)
		self.credentials = credentials
	}
	
	fileprivate init(client: ValorantClient, credentials: Credentials) {
		self.client = client
		self.credentials = credentials
	}
	
	func save(using keychain: Keychain) async {
		credentials.save(to: keychain)
		Self.stored = await client.store()
	}
	
	func reauthenticated() async throws -> Self {
		try await Self.authenticated(using: credentials)
	}
}

extension ValorantClient.SavedData: DefaultsValueConvertible {}
