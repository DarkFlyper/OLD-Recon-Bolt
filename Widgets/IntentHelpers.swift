import Intents
import ValorantAPI
import HandyOperators
import SwiftUI

protocol FetchingIntent where Self: INIntent {
	func loadAccount() async throws -> StoredAccount
}

extension FetchingIntent {
	func loadAccount() async throws -> StoredAccount {
		try await Managers.accounts.getActiveAccount()
	}
}

protocol SelfFetchingIntent: FetchingIntent {
	var useActiveAccount: NSNumber? { get }
	var account: Account? { get }
}

extension SelfFetchingIntent {
	func loadAccount() async throws -> StoredAccount {
		if useActiveAccount != 0 {
			return try await Managers.accounts.getActiveAccount()
		} else {
			let rawAccount = try account ??? GetAccountError.noAccountSpecified
			let accountID = try rawAccount.identifier.flatMap(User.ID.init(_:)) ??? GetAccountError.malformedAccount
			return try await Managers.accounts.loadAccount(for: accountID)
		}
	}
}

private extension AccountManager {
	func getActiveAccount() throws -> StoredAccount {
		try activeAccount ??? GetAccountError.noAccountActive(accountLoadError)
	}
}

private enum GetAccountError: Error, LocalizedError {
	case noAccountActive(String?)
	case noAccountSpecified
	case malformedAccount
	case unknownAccountID(User.ID)
	
	var errorDescription: String? {
		switch self {
		case .noAccountActive(let desc):
			return "Could not load active account!\n\(desc ?? "<no details>")"
		case .noAccountSpecified:
			return "No account specified."
		case .malformedAccount:
			return "Malformed account."
		case .unknownAccountID(let id):
			return "Missing account for ID \(id)"
		}
	}
}
