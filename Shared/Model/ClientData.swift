import Foundation
import ValorantAPI
import UserDefault
import HandyOperators

final class AccountManager: ObservableObject {
	let keychain: any Keychain
	
	@Published var activeAccount: StoredAccount? = nil {
		didSet {
			Storage.activeAccount = activeAccount?.id
			Task { await updateClientVersion() }
		}
	}
	
	@Published var storedAccounts: [User.ID] = Storage.storedAccounts {
		didSet {
			Storage.storedAccounts = storedAccounts
		}
	}
	
	@Published var clientVersion = Storage.clientVersion {
		didSet {
			Storage.clientVersion = clientVersion
			Task { await updateClientVersion() }
		}
	}
	
	var requiresAction: Bool {
		activeAccount?.session.hasExpired != false
	}
	
	init() {
		self.keychain = .standard
		
		do {
			self.activeAccount = try Storage.activeAccount.map(loadAccount(for:))
		} catch {
			print("could not load active account!", error)
			dump(Storage.activeAccount)
			dump(error)
		}
	}
	
#if DEBUG
	static let mocked = AccountManager(mockAccounts: [.init()], activeAccount: .mocked)
	
	@_disfavoredOverload
	init(mockAccounts: [User.ID] = [], activeAccount: StoredAccount? = nil) {
		self.keychain = MockKeychain()
		self.activeAccount = activeAccount
		self.storedAccounts = mockAccounts
		if let activeAccount, !self.storedAccounts.contains(activeAccount.id) {
			self.storedAccounts.append(activeAccount.id)
		}
	}
#endif
	
	func loadAccount(for id: User.ID) throws -> StoredAccount {
		try .init(loadingFor: id, from: keychain)
	}
	
	func addAccount(using session: APISession) {
		storedAccounts.removeAll { $0 == session.userID }
		if !storedAccounts.contains(session.userID) {
			storedAccounts.append(session.userID)
		}
		activeAccount = StoredAccount(session: session, keychain: keychain)
	}
	
	func updateClientVersion() async {
		guard let clientVersion else { return }
		await activeAccount?.client.setClientVersion(clientVersion)
	}
	
	private enum Storage {
		@UserDefault("AccountManager.activeAccount")
		static var activeAccount: User.ID?
		@UserDefault("AccountManager.storedAccounts")
		static var storedAccounts: [User.ID] = []
		@UserDefault("AccountManager.clientVersion")
		static var clientVersion: String?
	}
}

final class StoredAccount: ObservableObject, Identifiable {
	let keychain: any Keychain
	
	@Published private(set) var session: APISession {
		didSet { save() }
	}
	
	private(set) lazy var client = ValorantClient(session: session) <- {
		$0.onSessionUpdate { [weak self] session in
			guard let self else { return }
			self.session = session
			self.save()
		}
	}
	
	var id: User.ID { session.userID }
	
	fileprivate init(session: APISession, keychain: any Keychain) {
		self.keychain = keychain
		self.session = session
		save()
	}
	
	fileprivate init(loadingFor id: User.ID, from keychain: any Keychain) throws {
		self.keychain = keychain
		let stored = try keychain[id.rawID.description] ??? LoadingError.noStoredSession
		self.session = try JSONDecoder().decode(APISession.self, from: stored)
	}
	
	func save() {
		keychain[id.rawID.description] = try! JSONEncoder().encode(session)
		print("saved account for \(id)")
	}
	
	enum LoadingError: Error {
		case noStoredSession
	}
	
	#if DEBUG
	static let mocked = StoredAccount(session: .mocked, keychain: MockKeychain())
	#endif
}
