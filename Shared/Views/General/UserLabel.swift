import SwiftUI
import ValorantAPI

struct UserLabel: View {
	var userID: User.ID
	var shouldAutoUpdate = true
	
	@LocalData var user: User?
	
	var body: some View {
		HStack(spacing: 4) {
			if let user {
				let tagLine = Text("#\(user.tagLine)")
					.fontWeight(.regular)
					.foregroundColor(.secondary)
				
				Text("\(user.gameName) \(tagLine)")
					.fontWeight(.semibold)
			} else {
				Text("Unknown Player")
					.fontWeight(.semibold)
					.foregroundStyle(.secondary)
					.placeholder(if: user == nil)
			}
		}
		.withLocalData($user, id: userID, shouldAutoUpdate: shouldAutoUpdate)
	}
}

extension UserLabel {
	init(userID: User.ID, shouldAutoUpdate: Bool = true) {
		self.init(
			userID: userID,
			shouldAutoUpdate: shouldAutoUpdate,
			user: .init(id: userID)
		)
	}
}

#if DEBUG
struct UserLabel_Previews: PreviewProvider {
    static var previews: some View {
		VStack {
			UserLabel(userID: PreviewData.userID)
			UserLabel(userID: .init()) // randomized
		}
    }
}
#endif
