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

extension BasicMatchInfo {
	var queueName: String {
		if provisioningFlowID == .customGame {
			return "Custom"
		} else {
			return queueID?.name ?? "Unknown Queue"
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
		case "snowball":
			return "Snowball Fight"
		case let other:
			return other.capitalized
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
		case .pbe:
			return "PBE"
		default:
			return "<Unknown Location>"
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
		case .sessionExpired:
			return "Your session has expired! Please sign in again."
		case .sessionResumptionFailure(let error):
			return "Your session could not be resumed. \(error)"
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

extension CGPoint {
	public init(_ position: Position) {
		self.init(x: position.x, y: position.y)
	}
}
