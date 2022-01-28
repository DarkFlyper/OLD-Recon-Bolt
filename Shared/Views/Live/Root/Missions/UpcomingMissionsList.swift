import SwiftUI
import ValorantAPI

struct UpcomingMissionsList: View {
	var title: String
	var missions: ArraySlice<MissionInfo>
	@State var isExpanded = false
	
	private static let dateFormatter = RelativeDateTimeFormatter()
	
	var body: some View {
		if !missions.isEmpty {
			Divider()
			
			VStack(spacing: 16) {
				let totalXP = missions.map(\.xpGrant).reduce(0, +)
				
				Button {
					withAnimation { isExpanded.toggle() }
				} label: {
					HStack {
						Image(systemName: "chevron.down")
							.rotationEffect(.degrees(isExpanded ? 0 : -90))
						
						Text("\(missions.count) \(title)")
							.multilineTextAlignment(.leading)
						
						Spacer()
						
						Text("+\(totalXP) XP")
							.font(.caption.weight(.medium))
							.foregroundStyle(.secondary)
					}
					.font(.headline)
				}
				
				if isExpanded {
					let byActivation = missions.chunked(on: \.activationDate!)
					ForEach(byActivation, id: \.0) { (date, missions) in
						GroupBox {
							Text(date, formatter: Self.dateFormatter)
								.font(.subheadline.weight(.semibold))
							
							Divider()
							
							VStack(spacing: 16) {
								ForEach(missions) {
									MissionView(missionInfo: $0)
								}
							}
						}
					}
				}
			}
			.padding(16)
		}
	}
}
