import Foundation

struct UserInfo: Codable {
	var account: Account
	var id: UUID
	
	private enum CodingKeys: String, CodingKey {
		case account = "acct"
		case id = "sub"
	}
	
	struct Account: Codable {
		var gameName: String
		var tagLine: String
		var createdAt: Date
		
		var name: String {
			"\(gameName) #\(tagLine)"
		}
	}
}
