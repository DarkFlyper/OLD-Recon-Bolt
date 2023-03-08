import Intents

let isInSwiftUIPreview = false // lol

final class IntentHandler: INExtension {
	@MainActor
	private static let accountManager = AccountManager()
	
    override func handler(for intent: INIntent) -> Any { self }
	
	typealias Accounts = INObjectCollection<Account>
	
	func provideAccountOptionsCollection() async throws -> Accounts {
		let accountIDs = await Self.accountManager.storedAccounts
		let manager = LocalDataProvider.shared.userManager
		if let activeAccount = await Self.accountManager.activeAccount {
			try await activeAccount.client.fetchUsers(for: accountIDs)
		} else {
			print("no active account!")
		}
		
		var accounts: [Account] = []
		for accountID in accountIDs {
			let user = await manager.cachedObject(for: accountID)
			accounts.append(.init(
				identifier: accountID.rawID.description,
				display: user?.name ?? "<Unknown Account>"
			))
		}
		return INObjectCollection(items: accounts)
	}
}

extension IntentHandler: ViewStoreIntentHandling {
	func provideAccountOptionsCollection(for intent: ViewStoreIntent) async throws -> Accounts {
		try await provideAccountOptionsCollection()
	}
}

extension IntentHandler: ViewMissionsIntentHandling {
	func provideAccountOptionsCollection(for intent: ViewMissionsIntent) async throws -> Accounts {
		try await provideAccountOptionsCollection()
	}
}

extension IntentHandler: ViewRankIntentHandling {
	func provideAccountOptionsCollection(for intent: ViewRankIntent) async throws -> Accounts {
		// TODO: offer bookmarks as well
		try await provideAccountOptionsCollection()
	}
}
