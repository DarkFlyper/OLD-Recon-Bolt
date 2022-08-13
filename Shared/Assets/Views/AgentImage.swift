import SwiftUI
import ValorantAPI

typealias AgentImage = AssetImageView<_AgentImageProvider>
struct _AgentImageProvider: AssetImageProvider {
	static let assetPath = \AssetCollection.agents
}

extension AgentImage {
	static func icon(_ id: Agent.ID) -> Self {
		Self(id: id, getImage: \.displayIcon)
	}
	
	static func bustPortrait(_ id: Agent.ID) -> Self {
		Self(id: id, getImage: \.bustPortrait)
	}
	
	static func fullPortrait(_ id: Agent.ID) -> Self {
		Self(id: id, getImage: \.fullPortrait)
	}
	
	static func fullPortraitV2(_ id: Agent.ID) -> Self {
		Self(id: id, getImage: \.fullPortraitV2)
	}
	
	static func killfeedPortrait(_ id: Agent.ID) -> Self {
		Self(id: id, getImage: \.killfeedPortrait)
	}
	
	static func ability(_ id: Agent.ID, slot: AgentInfo.Ability.Slot) -> Self {
		Self(id: id, renderingMode: .template) { $0.ability(slot)?.displayIcon }
	}
}

#if DEBUG
struct AgentImage_Previews: PreviewProvider {
	static var previews: some View {
		Group {
			AgentImage.icon(.omen)
				.frame(height: 80)
			AgentImage.fullPortrait(.omen)
			AgentImage.bustPortrait(.omen)
		}
		.previewLayout(.sizeThatFits)
	}
}
#endif
