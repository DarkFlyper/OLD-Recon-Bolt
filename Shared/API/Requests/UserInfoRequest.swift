import Foundation
import Combine

struct UserInfoRequest: JSONJSONRequest {
	var url: URL { authBaseURL.appendingPathComponent("userinfo") }
	
	typealias Response = UserInfo
}

extension Client {
	func getUserInfo() -> AnyPublisher<UserInfo, Error> {
		send(UserInfoRequest())
	} 
}
