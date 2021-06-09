import Foundation
import ValorantAPI
import UserDefault
import HandyOperators

protocol ClientData {
	var user: User { get }
	var client: ValorantClient { get }
	var matchList: MatchList { get set }
	
	static func authenticated(using credentials: Credentials) async throws -> ClientData
	func reauthenticated() async throws -> ClientData
	
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
	var user: User { codableData.user }
	
	var client: ValorantClient { codableData.client }
	
	var matchList: MatchList {
		get { codableData.matchList }
		set { codableData.matchList = newValue }
	}
	
	private var codableData: CodableData
	private var credentials: Credentials
	
	@UserDefault("ClientData.stored")
	private static var stored: CodableData?
	
	static func authenticated(using credentials: Credentials) async throws -> ClientData {
		try await _authenticated(using: credentials)
	}
	
	private static func _authenticated(using credentials: Credentials) async throws -> Self {
		let client = try await ValorantClient.authenticated(
			username: credentials.username,
			password: credentials.password,
			region: credentials.region
		)
		let userInfo = try await client.getUserInfo()
		return Self(client: client, userInfo: userInfo, credentials: credentials)
	}
	
	init?(using keychain: Keychain) {
		guard
			let credentials = Credentials(from: keychain),
			let stored = Self.stored
		else { return nil }
		
		self.codableData = stored
		self.credentials = credentials
	}
	
	fileprivate init(client: ValorantClient, userInfo: UserInfo, credentials: Credentials) {
		self.codableData = .init(client: client, userInfo: userInfo, matchList: .init(user: .init(userInfo)))
		self.credentials = credentials
	}
	
	func save(using keychain: Keychain) {
		credentials.save(to: keychain)
		Self.stored = codableData
	}
	
	func reauthenticated() async throws -> ClientData {
		try await Self._authenticated(using: credentials)
			// TODO: switching to GRDB will make this unnecessary
			<- { $0.codableData.matchList = codableData.matchList }
	}
	
	private struct CodableData: Codable, DefaultsValueConvertible {
		var client: ValorantClient
		let userInfo: UserInfo
		var user: User { .init(userInfo) }
		var matchList: MatchList
	}
}
