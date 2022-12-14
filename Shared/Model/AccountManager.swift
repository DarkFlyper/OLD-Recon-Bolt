import Foundation
import Combine
import ValorantAPI
import UserDefault
import HandyOperators

@MainActor
final class AccountManager: ObservableObject {
	let keychain: any Keychain
	@Published var multifactorPrompt: MultifactorPrompt?
	
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
			self.activeAccount = try Storage.activeAccount.map { try loadAccount(for: $0) }
		} catch {
			print("could not load active account!", error)
			dump(Storage.activeAccount)
			dump(error)
		}
	}
	
#if DEBUG
	static let mocked = AccountManager(mockAccounts: [.init()], activeAccount: .mocked)
	static let mockEmpty = AccountManager(mockAccounts: [])
	
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
		try .init(loadingFor: id, using: context)
	}
	
	func addAccount(using credentials: Credentials) async throws {
		let activeSession = activeAccount?.session
		let session = try await APISession(
			credentials: credentials,
			withCookiesFrom: activeSession?.credentials.username == credentials.username ? activeSession : nil,
			multifactorHandler: handleMultifactor(info:)
		)
		if !storedAccounts.contains(session.userID) {
			storedAccounts.append(session.userID)
		}
		activeAccount = StoredAccount(session: session, context: context)
	}
	
	func toggleActive(_ id: User.ID) throws {
		if activeAccount?.id == id {
			activeAccount = nil
		} else {
			try setActive(id)
		}
	}
	
	func setActive(_ id: User.ID) throws {
		guard activeAccount?.id != id else { return }
		activeAccount = try loadAccount(for: id)
	}
	
	private var context: StoredAccount.Context {
		.init(keychain: keychain, multifactorHandler: handleMultifactor(info:))
	}
	
	func updateClientVersion() async {
		guard let clientVersion else { return }
		activeAccount?.setClientVersion(clientVersion)
	}
	
	private enum Storage {
		@UserDefault("AccountManager.activeAccount", migratingTo: .shared)
		static var activeAccount: User.ID?
		@UserDefault("AccountManager.storedAccounts", migratingTo: .shared)
		static var storedAccounts: [User.ID] = []
		@UserDefault("AccountManager.clientVersion", migratingTo: .shared)
		static var clientVersion: String?
	}
	
	@MainActor
	func handleMultifactor(info: MultifactorInfo) async throws -> String {
		defer { multifactorPrompt = nil }
		let code = try await withRobustThrowingContinuation { completion in
			multifactorPrompt = .init(info: info, completion: completion)
		}
		return code
	}
	
	enum MultifactorPromptError: Error, LocalizedError {
		case cancelled
		
		var errorDescription: String? {
			switch self {
			case .cancelled:
				return "Multifactor Prompt Cancelled."
			}
		}
	}
}

struct MultifactorPrompt: Identifiable {
	let id = UUID()
	let info: MultifactorInfo
	let completion: (Result<String, Error>) -> Void
}

final class StoredAccount: ObservableObject, Identifiable {
	let context: Context
	
	@Published private(set) var session: APISession {
		didSet { save() }
	}
	
	private(set) lazy var client = ValorantClient(
		session: session,
		multifactorHandler: context.multifactorHandler
	) <- {
		sessionUpdateListener = $0.onSessionUpdate { [weak self] session in
			guard let self else { return }
			print("storing updated session")
			self.session = session
		}
	}
	private var sessionUpdateListener: AnyCancellable?
	
	var id: User.ID { session.userID }
	
	var location: Location { session.location }
	
	fileprivate init(session: APISession, context: Context) {
		self.context = context
		self.session = session
		save()
	}
	
	fileprivate init(loadingFor id: User.ID, using context: Context) throws {
		self.context = context
		let stored = try context.keychain[id.rawID.description] ??? LoadingError.noStoredSession
		self.session = try JSONDecoder().decode(APISession.self, from: stored)
	}
	
	func save() {
		context.keychain[id.rawID.description] = try! JSONEncoder().encode(session)
		print("saved account for \(id)")
	}
	
	func setClientVersion(_ version: String) {
		client.clientVersion = version
	}
	
	enum LoadingError: Error, LocalizedError {
		case noStoredSession
		
		var errorDescription: String? {
			switch self {
			case .noStoredSession:
				return "Missing session for account."
			}
		}
	}
	
	#if DEBUG
	static let mocked = StoredAccount(session: .mocked, context: .init(
		keychain: MockKeychain(),
		multifactorHandler: { _ in fatalError() }
	))
	#endif
	
	struct Context {
		var keychain: any Keychain
		var multifactorHandler: MultifactorHandler
	}
}

extension User.ID: DefaultsValueConvertible {
	public typealias DefaultsRepresentation = Data // use codable
}
