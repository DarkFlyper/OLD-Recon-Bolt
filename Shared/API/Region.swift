import Foundation

enum Region: Int, Codable, CaseIterable {
	case europe
	case northAmerica
	case korea
	case asiaPacific
	case brazil
	case latinAmerica
	
	var subdomain: String {
		switch self {
		case .europe:
			return "eu"
		case .korea:
			return "kr"
		case .asiaPacific:
			return "ap"
		case .northAmerica, .brazil, .latinAmerica:
			return "na"
		}
	}
}
