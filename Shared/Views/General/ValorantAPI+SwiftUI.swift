import SwiftUI
import ValorantAPI
import ArrayBuilder

extension Team.ID {
	var color: Color? {
		switch rawID {
		case "Blue":
			return .valorantBlue
		case "Red":
			return .valorantRed
		default:
			return nil
		}
	}
}

extension Location: Identifiable {
	public var id: String { "\(shard):\(region)" }
}

extension Location {
	var name: String {
		switch self {
		case .europe:
			return String(localized: "Europe", table: "Locations")
		case .northAmerica:
			return String(localized: "North America", table: "Locations")
		case .korea:
			return String(localized: "Korea", table: "Locations")
		case .asiaPacific:
			return String(localized: "Asia Pacific", table: "Locations")
		case .brazil:
			return String(localized: "Brazil", table: "Locations")
		case .latinAmerica:
			return String(localized: "Latin America", table: "Locations")
		case .pbe:
			return String(localized: "PBE", table: "Locations")
		default:
			return String(localized: "Unknown Location", table: "Locations")
		}
	}
}

extension APIError: LocalizedError {
	public var errorDescription: String? {
		switch self {
		case .unauthorized:
			return String(localized: "The API rejected your authorization.", table: "Errors", comment: "Riot API Error")
		case .tokenFailure(message: let message):
			return String(localized: "Your token has expired. \(message)", table: "Errors", comment: "Riot API Error")
		case .sessionExpired:
			return String(localized: "Your session has expired! Please sign in again.", table: "Errors", comment: "Riot API Error")
		case .sessionResumptionFailure(let error):
			return String(localized: "Your session could not be resumed. \(error.localizedDescription)", table: "Errors", comment: "Riot API Error")
		case .scheduledDowntime:
			return String(localized: "Valorant is currently undergoing scheduled maintenance. Riot is probably updating the game!", table: "Errors", comment: "Riot API Error")
		case .resourceNotFound:
			return String(localized: "The resource could not be found.", table: "Errors", comment: "Riot API Error")
		case .badResponseCode(400, _, let error?) where error.errorCode == "INVALID_HEADERS":
			return String(localized: "Invalid Headers: \(error.message)", table: "Errors", comment: "Riot API Error")
		case .badResponseCode(404, _, let error?) where error.errorCode == "MATCH_NOT_FOUND":
			return String(localized: "This match could not be loaded! Valorant discards match details for older matches after a few months.", table: "Errors", comment: "Riot API Error")
		case .badResponseCode(let code, _, nil):
			return String(localized: "The API returned an error code \(code).", table: "Errors", comment: "Riot API Error")
		case .badResponseCode(let code, _, let error?):
			return String(localized: "The API returned an error code \(code), i.e. \(error.errorCode). \(error.message)", table: "Errors", comment: "Riot API Error")
		case .rateLimited(retryAfter: let delay):
			return [String].build {
				String(localized: "You are sending too many requests.", table: "Errors", comment: "Riot API Error")
				delay.map { String(localized: "Please try again in \($0) seconds.", table: "Errors", comment: "Riot API Error") }
			}.joined(separator: " ")
		}
	}
}

extension CGPoint {
	public init(_ position: Position) {
		self.init(x: position.x, y: position.y)
	}
}
