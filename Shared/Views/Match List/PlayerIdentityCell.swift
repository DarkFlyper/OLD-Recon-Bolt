import SwiftUI
import ValorantAPI

struct PlayerIdentityCell: View {
	let user: User
	let identity: Player.Identity
	
	@Environment(\.assets) private var assets
	
	var body: some View {
		VStack(spacing: 0) {
			HStack {
				HStack(spacing: 4) {
					Text(user.gameName)
						.fontWeight(.semibold)
					
					Text("#\(user.tagLine)")
						.foregroundStyle(.secondary)
				}
				
				Spacer()
				
				if let title = assets?.playerTitles[identity.titleID]?.titleText {
					Text(title)
						.fontWeight(.medium)
				}
				
				Spacer()
				
				Text("Level \(identity.accountLevel)")
			}
			.padding()
			
			PlayerCardImage.wideArt(identity.cardID)
		}
		.listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
	}
}

#if DEBUG
struct PlayerIdentityCell_Previews: PreviewProvider {
	static var previews: some View {
		PlayerIdentityCell(user: PreviewData.user, identity: PreviewData.userIdentity)
			.previewLayout(.sizeThatFits)
	}
}
#endif
