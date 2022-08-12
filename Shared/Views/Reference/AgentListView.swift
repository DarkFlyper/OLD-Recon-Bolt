import SwiftUI

struct AgentListView: View {
	@Environment(\.assets) private var assets
	
	var body: some View {
		List {
			if let assets {
				let agents = assets.agents.values.sorted(on: \.displayName)
				ForEach(agents) { agent in
					NavigationLink(destination: AgentInfoView(agent: agent)) {
						row(for: agent)
					}
				}
			}
		}
		.navigationTitle("Agents")
	}
	
	func row(for agent: AgentInfo) -> some View {
		HStack(spacing: 12) {
			SquareAgentIcon(agentID: agent.id)
				.frame(height: 48)
			
			Text("\(agent.displayName)")
				.fontWeight(.medium)
				.font(.title2)
			
			Spacer()
		}
		.padding(.vertical, 4)
	}
}

#if DEBUG
struct AgentListView_Previews: PreviewProvider {
	static var previews: some View {
		AgentListView()
			.withToolbar()
	}
}
#endif
