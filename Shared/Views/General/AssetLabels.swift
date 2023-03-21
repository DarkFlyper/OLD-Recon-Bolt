import SwiftUI
import ValorantAPI

struct QueueLabel: View {
	var queue: QueueID
	
	@Environment(\.assets) private var assets
	
	var body: some View {
		if let queue = assets?.queues[queue] {
			Text(queue.name)
		} else {
			Text(queue.name)
				.foregroundStyle(.secondary)
		}
	}
}

struct AgentLabel: View {
	var agent: Agent.ID
	
	@Environment(\.assets) private var assets
	
	var body: some View {
		if let agent = assets?.agents[agent] {
			Text(agent.displayName)
		} else {
			Text("Unknown Agent")
				.foregroundStyle(.secondary)
		}
	}
}

struct AssetLabels_Previews: PreviewProvider {
    static var previews: some View {
		VStack {
			QueueLabel(queue: .newMap)
			QueueLabel(queue: .snowballFight)
			AgentLabel(agent: .harbor)
		}
    }
}
