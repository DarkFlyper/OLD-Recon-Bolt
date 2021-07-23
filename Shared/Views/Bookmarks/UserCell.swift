import SwiftUI
import ValorantAPI

struct UserCell: View {
	let userID: User.ID
	@Binding var isSelected: Bool
	@State var user: User?
	@State var identity: Player.Identity?
	@State var summary: CareerSummary?
	
	var body: some View {
		let artworkSize = 64.0
		
		NavigationLink(isActive: $isSelected) {
			MatchListView(userID: userID, user: user)
		} label: {
			HStack(spacing: 10) {
				if let identity = identity {
					PlayerCardImage.smallArt(identity.cardID)
						.frame(width: artworkSize, height: artworkSize)
						.mask(RoundedRectangle(cornerRadius: 4, style: .continuous))
				}
				
				VStack(alignment: .leading) {
					if let user = user {
						Text(user.gameName)
							.fontWeight(.semibold)
						+ Text(" #\(user.tagLine)")
							.foregroundColor(.secondary)
					} else {
						Text("Unknown Player")
					}
					
					if let identity = identity {
						Text("Level \(identity.accountLevel)")
					}
				}
				
				Spacer()
				
				RankInfoView(summary: summary)
					.frame(width: artworkSize, height: artworkSize)
			}
		}
		.padding(.vertical, 8)
		.withLocalData($user, id: userID)
		.withLocalData($identity, id: userID)
		.withLocalData($summary, id: userID, shouldAutoUpdate: true)
	}
}

#if DEBUG
struct UserCell_Previews: PreviewProvider {
	static var previews: some View {
		Group {
			UserCell(
				userID: PreviewData.userID,
				isSelected: .constant(false),
				user: PreviewData.user,
				identity: PreviewData.userIdentity
			)
			
			UserCell(
				userID: PreviewData.userID,
				isSelected: .constant(false),
				user: PreviewData.user,
				identity: PreviewData.userIdentity,
				summary: PreviewData.summary
			)
		}
		.padding()
		.inEachColorScheme()
		.frame(width: 400)
		.previewLayout(.sizeThatFits)
	}
}
#endif
