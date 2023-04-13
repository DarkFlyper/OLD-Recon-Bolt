import Intents
import ValorantAPI
import HandyOperators
import SwiftUI

protocol FetchingIntent where Self: INIntent {
	func accountID() throws -> User.ID?
}

extension FetchingIntent {
	func accountID() throws -> User.ID? { nil }
}

protocol SelfFetchingIntent: FetchingIntent {
	var useActiveAccount: NSNumber? { get }
	var account: Account? { get }
}

extension SelfFetchingIntent {
	func accountID() throws -> User.ID? {
		guard useActiveAccount == 0 else { return nil }
		let rawAccount = try account ??? GetAccountError.noAccountSpecified
		return try rawAccount.userID()
	}
}

extension Account {
	func userID() throws -> User.ID {
		try identifier.flatMap(User.ID.init(_:)) ??? GetAccountError.malformedAccount
	}
}

extension AccountManager {
	func getAccount(for id: User.ID?) throws -> StoredAccount {
		try id.map(loadAccount(for:)) ?? getActiveAccount()
	}
	
	private func getActiveAccount() throws -> StoredAccount {
		try activeAccount ??? GetAccountError.noAccountActive(accountLoadError)
	}
}

private enum GetAccountError: Error, LocalizedError {
	case noAccountActive(String?)
	case noAccountSpecified
	case malformedAccount
	
	var errorDescription: String? {
		switch self {
		case .noAccountActive(let desc):
			let lines = [
				String(localized: "Could not load active account!", table: "Errors", comment: "error loading the account for a widget"),
				desc
			]
			return lines.compacted().joined(separator: "\n")
		case .noAccountSpecified:
			return String(localized: "No account specified.", table: "Errors", comment: "error loading the account for a widget.")
		case .malformedAccount:
			return String(localized: "Malformed account.", table: "Errors", comment: "error loading the account for a widget.")
		}
	}
}
