import SwiftUI
import ValorantAPI

typealias AgentImage = _AssetImageView<_AgentImageProvider>
struct _AgentImageProvider: _AssetImageProvider {
	static let assetPath = \AssetCollection.agents
}

#if DEBUG
struct AgentImage_Previews: PreviewProvider {
	static var previews: some View {
		Group {
			AgentImage.displayIcon(.omen)
				.frame(height: 80)
			AgentImage.fullPortrait(.omen)
			AgentImage.bustPortrait(.omen)
		}
		.previewLayout(.sizeThatFits)
		.withPreviewAssets()
	}
}
#endif
