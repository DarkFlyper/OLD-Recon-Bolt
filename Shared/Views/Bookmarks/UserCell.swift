import SwiftUI
import ValorantAPI

struct UserCell: View {
	let userID: User.ID
	@Binding var isSelected: Bool
	var shouldAutoUpdate = false
	
	@LocalData var user: User?
	@LocalData var identity: Player.Identity?
	@LocalData var summary: CareerSummary?
	
	var body: some View {
		let artworkSize = 64.0
		
		TransparentNavigationLink(isActive: $isSelected) {
			MatchListView(userID: userID)
		} label: {
			HStack(spacing: 10) {
				if let identity {
					PlayerCardImage.small(identity.cardID)
						.frame(width: artworkSize, height: artworkSize)
						.mask(RoundedRectangle(cornerRadius: 4, style: .continuous))
				}
				
				VStack(alignment: .leading, spacing: 4) {
					UserLabel(userID: userID, shouldAutoUpdate: false)
					
					if let identity {
						Text("Level \(identity.accountLevel)", comment: "Bookmark/Player List: player level")
					}
				}
				
				Spacer()
				
				RankInfoView(summary: summary, size: artworkSize)
			}
		}
		.padding(.vertical, 8)
		.withLocalData($user, id: userID)
		.withLocalData($identity, id: userID)
		.withLocalData($summary, id: userID, shouldAutoUpdate: shouldAutoUpdate)
	}
}

extension UserCell {
	init(userID: User.ID, isSelected: Binding<Bool>) {
		self.init(
			userID: userID,
			isSelected: isSelected,
			user: .init(id: userID),
			identity: .init(id: userID),
			summary: .init(id: userID)
		)
	}
}

#if DEBUG
struct UserCell_Previews: PreviewProvider {
	static var previews: some View {
		List {
			UserCell(userID: PreviewData.userID, isSelected: .constant(false))
			
			UserCell(
				userID: PreviewData.userID,
				isSelected: .constant(false),
				user: .init(preview: PreviewData.user),
				identity: .init(preview: PreviewData.userIdentity),
				summary: .init(preview: PreviewData.summary)
			)
			.lockingLocalData()
		}
		.withToolbar()
	}
}
#endif
