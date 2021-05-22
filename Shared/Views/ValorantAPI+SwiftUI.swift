import SwiftUI
import ValorantAPI

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

extension MapID {
	@ViewBuilder
	var mapImage: some View {
		if let name = mapName {
			Image("maps/\(name)")
				.resizable()
		} else {
			Rectangle()
				.size(width: 400, height: 225)
				.fill(Color.gray)
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
