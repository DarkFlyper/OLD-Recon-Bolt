import SwiftUI
import ValorantAPI

struct SquareAgentIcon: View {
	var agentID: Agent.ID
	var cornerRadius: CGFloat = 8
	var backgroundColor: Color = .primary.opacity(0.25)
	
	var body: some View {
		AgentImage.icon(agentID)
			.background(backgroundColor.opacity(0.5))
			.clipShape(RoundedRectangle(cornerRadius: cornerRadius - 1, style: .continuous))
			.padding(1)
			.overlay {
				RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
					.strokeBorder(backgroundColor)
			}
	}
}
