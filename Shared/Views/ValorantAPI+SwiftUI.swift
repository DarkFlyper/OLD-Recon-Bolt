import SwiftUI
import ValorantAPI

extension Color {
	static let valorantBlue = Color(#colorLiteral(red: 0.4, green: 0.7607843137, blue: 0.662745098, alpha: 1))
	static let valorantRed = Color(#colorLiteral(red: 0.9411764706, green: 0.3607843137, blue: 0.3411764706, alpha: 1))
	static let valorantYellow = Color(#colorLiteral(red: 0.9176470588, green: 0.9333333333, blue: 0.6980392157, alpha: 1))
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
