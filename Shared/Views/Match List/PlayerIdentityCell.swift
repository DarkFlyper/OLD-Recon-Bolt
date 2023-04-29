import SwiftUI
import ValorantAPI
import HandyOperators

struct PlayerIdentityCell: View {
	let user: User?
	let identity: Player.Identity?
	
	@Environment(\.assets) private var assets
	@Environment(\.shouldAnonymize) private var shouldAnonymize
	
	var body: some View {
		VStack(spacing: 0) {
			HStack {
				HStack(spacing: 4) {
					if let user, !shouldAnonymize(user.id) {
						Text(user.gameName)
							.fontWeight(.semibold)
						
						Text("#\(user.tagLine)")
							.foregroundStyle(.secondary)
					} else {
						Text("Player")
							.fontWeight(.semibold)
							.foregroundStyle(.secondary)
							.placeholder(if: user == nil)
					}
				}
				
				Spacer()
				
				if let identity, let title = assets?.playerTitles[identity.titleID]?.titleText {
					Text(title)
				}
			}
			.padding()
			
			if let identity {
				Divider().zIndex(1).overlay {
					Text("\(identity.accountLevel)")
						.fontWeight(.semibold)
						.foregroundStyle(.secondary)
						.frame(minWidth: 24)
						.padding(6)
						.padding(.horizontal, 4)
						.overlay(Capsule().stroke(.secondary))
						.background(Material.ultraThin)
						.mask(Capsule())
				}
			}
			
			PlayerCardImage.wide(identity?.cardID)
				.fixedSize(horizontal: false, vertical: true) // idk why i suddenly need this but i do
			
			Divider()
		}
		.listRowInsets(.init())
		.listRowSeparator(.hidden, edges: .bottom) // the separator is inset, which doesn't look great
	}
}

#if DEBUG
struct PlayerIdentityCell_Previews: PreviewProvider {
	static var previews: some View {
		Group {
			PlayerIdentityCell(user: PreviewData.user, identity: PreviewData.userIdentity)
			PlayerIdentityCell(user: PreviewData.user, identity: PreviewData.userIdentity <- {
				$0.accountLevel = 6
				$0.cardID = .init("8d82ec0a-4c3b-8458-d0b6-e1bb900671cf")!
			})
		}
		.previewLayout(.sizeThatFits)
	}
}
#endif
