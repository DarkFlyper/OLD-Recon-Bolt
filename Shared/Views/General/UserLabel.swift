import SwiftUI
import ValorantAPI

struct UserLabel: View {
	var userID: User.ID
	var shouldAutoUpdate = true
	
	@LocalData var user: User?
	
	var body: some View {
		HStack(spacing: 4) {
			if let user {
				Text(user.gameName)
					.fontWeight(.semibold)
				
				Text("#\(user.tagLine)")
					.foregroundStyle(.secondary)
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
