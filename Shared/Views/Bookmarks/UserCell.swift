import SwiftUI
import ValorantAPI

struct UserCell: View {
	let userID: User.ID
	@Binding var isSelected: Bool
	@State var user: User?
	@State var identity: Player.Identity?
	
	var body: some View {
		NavigationLink(isActive: $isSelected) {
			MatchListView(userID: userID, user: user)
		} label: {
			HStack(spacing: 10) {
				if let identity = identity {
					PlayerCardImage.smallArt(identity.cardID)
						.frame(width: 64, height: 64)
						.mask(RoundedRectangle(cornerRadius: 4, style: .continuous))
				}
				
				VStack(alignment: .leading) {
					if let user = user {
						HStack(spacing: 4) {
							Text(user.gameName)
								.fontWeight(.semibold)
							
							Text("#\(user.tagLine)")
								.foregroundStyle(.secondary)
						}
					} else {
						Text("Unknown Player")
					}
					
					if let identity = identity {
						Text("Level \(identity.accountLevel)")
					}
				}
				
				Spacer()
			}
		}
		.padding(.vertical, 8)
		.withLocalData($user, id: userID)
		.withLocalData($identity, id: userID)
	}
}

#if DEBUG
struct UserCell_Previews: PreviewProvider {
	static var previews: some View {
		UserCell(
			userID: PreviewData.userID,
			isSelected: .constant(false),
			user: PreviewData.user,
			identity: PreviewData.userIdentity
		)
		.padding()
		.frame(width: 400)
		.previewLayout(.sizeThatFits)
	}
}
#endif
