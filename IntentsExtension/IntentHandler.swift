import Intents
import ValorantAPI

let isInSwiftUIPreview = false // lol

final class IntentsExtension: INExtension {
	override func handler(for intent: INIntent) -> Any {
		// making a new instance causes it to refresh accounts & bookmarks
		IntentHandler()
	}
}

final class IntentHandler: NSObject {
	@MainActor
	private let accountManager = AccountManager()
	@MainActor
	private let bookmarkList = BookmarkList()
	
	typealias Accounts = INObjectCollection<Account>
	
	func provideAccountOptionsCollection() async throws -> Accounts {
		try await makeCollection(resolving: await accountManager.storedAccounts)
	}
	
	/// includes bookmarks
	func provideUserOptionsCollection() async throws -> Accounts {
		let accounts = await accountManager.storedAccounts
		let accountSet = Set(accounts)
		return try await makeCollection(
			resolving: accounts + bookmarkList
				.bookmarks
				.lazy
				.map(\.id)
				.filter { !accountSet.contains($0) }
		)
	}
	
	private func makeCollection(resolving userIDs: [User.ID]) async throws -> Accounts {
		if let activeAccount = await accountManager.activeAccount {
			try await activeAccount.client.fetchUsers(for: userIDs)
		}
		
		let manager = LocalDataProvider.shared.userManager
		var accounts: [Account] = []
		for userID in userIDs {
			let user = await manager.cachedObject(for: userID)
			accounts.append(.init(
				identifier: userID.rawID.description,
				display: user?.name ?? "Unknown Account"
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
		try await provideUserOptionsCollection()
	}
}

extension IntentHandler: ViewRankChangesIntentHandling {
	func provideAccountOptionsCollection(for intent: ViewRankChangesIntent) async throws -> Accounts {
		try await provideUserOptionsCollection()
	}
}
