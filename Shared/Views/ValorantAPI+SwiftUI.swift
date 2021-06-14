import SwiftUI
import ValorantAPI
import ArrayBuilder

extension Color {
	static let valorantBlue = Color("Valorant Blue")
	static let valorantRed = Color("Valorant Red")
	static let valorantSelf = Color("Valorant Self")
}

extension Team.ID {
	var color: Color? {
		switch rawValue {
		case "Blue":
			return .valorantBlue
		case "Red":
			return .valorantRed
		default:
			return nil
		}
	}
}

extension QueueID {
	var name: String {
		switch rawValue {
		case "ggteam":
			return "Escalation"
		case "spikerush":
			return "Spike Rush"
		case "newmap":
			return "New Map"
		case "onefa":
			return "Replication"
		case let other:
			return other.capitalized
		}
	}
}

extension Region {
	var name: String {
		switch self {
		case .europe:
			return "Europe"
		case .northAmerica:
			return "North America"
		case .korea:
			return "Korea"
		case .asiaPacific:
			return "Asia Pacific"
		case .brazil:
			return "Brazil"
		case .latinAmerica:
			return "Latin America"
		}
	}
}

extension ValorantClient.APIError: LocalizedError {
	public var errorDescription: String? {
		switch self {
		case .unauthorized:
			return "The API rejected your authorization."
		case .tokenFailure(message: let message):
			return "Your token has expired. \(message)"
		case .scheduledDowntime(message: let message):
			return "The API is down for scheduled maintenance. \(message)"
		case .resourceNotFound:
			return "The resource could not be found."
		case .badResponseCode(let code, _, nil):
			return "The API returned an error code \(code)."
		case .badResponseCode(let code, _, let error?):
			return "The API returned an error code \(code), i.e. \(error.errorCode). \(error.message)"
		case .rateLimited(retryAfter: let delay):
			return [String].build {
				"You are sending too many requests."
				delay.map { "Please try again in \($0) seconds." }
			}.joined(separator: " ")
		}
	}
}
