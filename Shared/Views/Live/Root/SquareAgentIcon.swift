import SwiftUI
import ValorantAPI

struct SquareAgentIcon: View {
	var agentID: Agent.ID
	
	var body: some View {
		let shape = RoundedRectangle(cornerRadius: 8, style: .continuous)
		AgentImage.icon(agentID)
			.background(Color(.lightGray).opacity(0.5))
			.clipShape(shape)
			.overlay { shape.stroke(Color(.lightGray)) }
	}
}
