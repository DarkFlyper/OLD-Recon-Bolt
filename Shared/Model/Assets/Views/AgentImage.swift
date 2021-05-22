import SwiftUI
import ValorantAPI

@dynamicMemberLookup
struct AgentImage: View {
	@EnvironmentObject var assetManager: AssetManager
	
	let agentID: Agent.ID
	let imageKeyPath: KeyPath<AgentInfo, AssetImage>
	
	static subscript(
		dynamicMember keyPath: KeyPath<AgentInfo, AssetImage>
	) -> (Agent.ID) -> Self {
		{ Self(agentID: $0, imageKeyPath: keyPath) }
	}
	
	var body: some View {
		let agentInfo = assetManager.assets?.agents[agentID]
		if let image = agentInfo?[keyPath: imageKeyPath].imageIfLoaded {
			image
				.resizable()
				.scaledToFit()
		} else {
			Color.gray
		}
	}
}

struct AgentImage_Previews: PreviewProvider {
	static let agentID = Agent.ID(UUID(uuidString: "8e253930-4c05-31dd-1b6c-968525494517")!)
	
	static var previews: some View {
		Group {
			AgentImage.displayIcon(agentID)
				.frame(height: 80)
			AgentImage.fullPortrait(agentID)
			AgentImage.bustPortrait(agentID)
		}
		.previewLayout(.sizeThatFits)
		.environmentObject(AssetManager.forPreviews)
	}
}
