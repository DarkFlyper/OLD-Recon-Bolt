import Intents

let isInSwiftUIPreview = false // lol

class IntentHandler: INExtension {
    override func handler(for intent: INIntent) -> Any {
        // This is the default implementation.  If you want different objects to handle different intents,
        // you can override this and return the handler you want for that particular intent.
        
        return ViewStoreHandler()
    }
}

final class ViewStoreHandler: NSObject, ViewStoreIntentHandling {
	@MainActor
	private static let accountManager = AccountManager()
	
	func provideAccountOptionsCollection(for intent: ViewStoreIntent) async throws -> INObjectCollection<Account> {
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
