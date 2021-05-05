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
