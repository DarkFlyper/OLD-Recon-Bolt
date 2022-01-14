import SwiftUI
import ValorantAPI

struct CurrentMissionsList: View {
	var title: String
	var missions: [MissionWithInfo]
	var countdownTarget: Date? = nil
	
	var body: some View {
		if !missions.isEmpty {
			Divider()
			
			VStack(spacing: 16) {
				HStack(alignment: .lastTextBaseline) {
					Text(title)
						.font(.headline)
						.multilineTextAlignment(.leading)
					
					Spacer()
					
					Group {
						if let countdownTarget = countdownTarget {
							CountdownText(target: countdownTarget)
							Image(systemName: "clock")
						}
					}
					.font(.caption.weight(.medium))
					.foregroundStyle(.secondary)
				}
				
				GroupBox {
					ForEach(missions, id: \.mission.id) { mission, missionInfo in
						if let missionInfo = missionInfo {
							MissionView(missionInfo: missionInfo, mission: mission)
						} else {
							Text("Unknown mission!")
						}
					}
				}
			}
			.padding(16)
		}
	}
}
