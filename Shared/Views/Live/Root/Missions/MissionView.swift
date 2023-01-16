import SwiftUI
import ValorantAPI

struct MissionView: View {
	var missionInfo: MissionInfo
	var mission: Mission?
	
	@Environment(\.assets) private var assets
	
	var body: some View {
		let resolved = ResolvedMission(info: missionInfo, mission: mission, assets: assets)
		let isComplete = mission?.isComplete == true
		
		VStack(spacing: 8) {
			HStack(alignment: .lastTextBaseline) {
				Text(resolved.name)
					.font(.subheadline)
					.opacity(isComplete ? 0.5 : 1)
				
				Spacer()
				
				if isComplete {
					Image(systemName: "checkmark.circle")
						.foregroundColor(.accentColor)
				} else {
					Text("+\(missionInfo.xpGrant) XP")
						.font(.caption.weight(.medium))
						.foregroundStyle(.secondary)
				}
			}
			
			if !isComplete, let progress = resolved.progress {
				VStack(spacing: 4) {
					GeometryReader { geometry in
						let fractionComplete = CGFloat(progress) / CGFloat(resolved.toComplete)
						Capsule()
							.opacity(0.1)
						Capsule()
							.foregroundColor(.accentColor)
							.frame(width: geometry.size.width * fractionComplete)
							.frame(maxWidth: .infinity, alignment: .leading)
					}
					.frame(height: 4)
					
					Text("\(progress)/\(resolved.toComplete)")
						.font(.caption)
						.foregroundStyle(.secondary)
						.frame(maxWidth: .infinity, alignment: .leading)
				}
			} else {
				Capsule()
					.frame(height: 2)
					.foregroundColor(isComplete ? .accentColor : .gray.opacity(0.1))
			}
		}
	}
}

#if DEBUG
struct MissionView_Previews: PreviewProvider {
	static let assets = AssetManager.forPreviews.assets
	static let data = PreviewData.contractDetails
	
	static var previews: some View {
		Group {
			VStack(spacing: 16) {
				ForEach(data.missions) { mission in
					MissionView(missionInfo: assets!.missions[mission.id]!, mission: mission)
				}
			}
			
			VStack(spacing: 8) {
				ForEach(data.missions) { mission in
					MissionView(missionInfo: assets!.missions[mission.id]!)
				}
			}
		}
		.padding()
		.frame(width: 300)
		.previewLayout(.sizeThatFits)
	}
}
#endif
