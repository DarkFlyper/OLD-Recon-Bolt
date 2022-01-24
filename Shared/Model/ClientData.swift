import Foundation
import ValorantAPI
import UserDefault
import HandyOperators

protocol ClientData {
	var userID: User.ID { get }
	var client: ValorantClient { get }
	
	static func authenticated(
		using credentials: Credentials,
		multifactorHandler: MultifactorHandler
	) async throws -> Self
	
	func setClientVersion(_ version: String) async
	
	init?()
	func save() async
}

extension ClientData {
	var userID: User.ID { client.userID }
	
	func setClientVersion(_ version: String) async {
		await client.setClientVersion(version)
		await save()
	}
}

final class ClientDataStore: ObservableObject {
	let keychain: Keychain
	@Published var data: ClientData? {
		didSet {
			// this won't catch when the client reestablishes its session from cookies, but the token only lasts an hour anyway, during which time recon bolt will likely keep running, so it's not worth storing to defaults.
			Task { await data?.save() }
		}
	}
	
	init<StoredData: ClientData>(keychain: Keychain, for _: StoredData.Type) {
		self.keychain = keychain
		self.data = StoredData()
	}
}

// TODO: this feels like unnecessary abstraction now that it no longer stores credentials
struct StandardClientData: ClientData {
	var client: ValorantClient
	
	@UserDefault("ClientData.stored")
	private static var stored: ValorantClient.SavedData?
	
	static func authenticated(
		using credentials: Credentials,
		multifactorHandler: MultifactorHandler
	) async throws -> Self {
		let session = try await APISession(
			username: credentials.username,
			password: credentials.password,
			multifactorHandler: multifactorHandler
		)
		let client = try ValorantClient(location: credentials.location, session: session)
		return Self(client: client)
	}
	
	init?() {
		guard
			let stored = Self.stored
		else { return nil }
		
		self.client = .init(from: stored)
	}
	
	private init(client: ValorantClient) {
		self.client = client
	}
	
	func save() async {
		Self.stored = await client.store()
	}
}

extension ValorantClient.SavedData: DefaultsValueConvertible {}
