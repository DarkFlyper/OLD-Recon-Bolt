import Intents
import ValorantAPI
import HandyOperators
import SwiftUI

protocol FetchingIntent where Self: INIntent {
	func loadAccount() async throws -> StoredAccount
}

extension FetchingIntent {
	func loadAccount() async throws -> StoredAccount {
		try await Managers.accounts.activeAccount ??? GetAccountError.missingAccount
	}
}

protocol SelfFetchingIntent: FetchingIntent {
	var useActiveAccount: NSNumber? { get }
	var account: Account? { get }
}

extension SelfFetchingIntent {
	func loadAccount() async throws -> StoredAccount {
		if useActiveAccount != 0 {
			return try await Managers.accounts.activeAccount ??? GetAccountError.missingAccount
		} else {
			let rawAccount = try account ??? GetAccountError.missingAccount
			let accountID = try rawAccount.identifier.flatMap(User.ID.init(_:)) ??? GetAccountError.malformedAccount
			return try await Managers.accounts.loadAccount(for: accountID)
		}
	}
}

private enum GetAccountError: Error, LocalizedError {
	case missingAccount
	case malformedAccount
	case unknownAccountID(User.ID)
	
	var errorDescription: String? {
		switch self {
		case .missingAccount:
			return "Missing Account!"
		case .malformedAccount:
			return "Malformed Account"
		case .unknownAccountID(let id):
			return "Missing Account for ID \(id)"
		}
	}
}

extension AccentColor {
	var color: Color {
		switch self {
		case .unknown:
			fallthrough
		case .red:
			return .valorantRed
		case .blue:
			return .valorantBlue
		case .highlight:
			return .valorantSelf
		case .primary:
			return .primary
		}
	}
}
