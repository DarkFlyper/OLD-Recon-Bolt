import SwiftUI
import ValorantAPI

struct MissionView: View {
	var missionInfo: MissionInfo
	var mission: Mission?
	
	@Environment(\.assets) private var assets
	
	var body: some View {
		VStack(spacing: 8) {
			let (objectiveID, progress) = mission?.objectiveProgress.singleElement ?? (nil, nil)
			let objectiveValue = missionInfo.objective(id: objectiveID)
			let toComplete = objectiveValue?.value
				?? missionInfo.progressToComplete // this is incorrect for e.g. the "you or your allies plant or defuse spikes" one, where it's 1 while the objectives correctly list it as 5
			
			let objective = (objectiveID ?? objectiveValue?.objectiveID)
				.flatMap { assets?.objectives[$0] }
			
			HStack(alignment: .lastTextBaseline) {
				let name = objective?.directive?
					.valorantLocalized(number: toComplete)
					?? missionInfo.displayName
					?? missionInfo.title
					?? "<Unnamed Mission>"
				
				Text(name)
					.font(.subheadline)
				
				Spacer()
				
				Text("+\(missionInfo.xpGrant) XP")
					.font(.caption.weight(.medium))
					.foregroundStyle(.secondary)
			}
			
			if let progress = progress {
				ProgressView(
					value: Double(progress),
					total: Double(toComplete),
					label: { EmptyView() },
					currentValueLabel: { Text("\(progress)/\(toComplete)") }
				)
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
		.inEachColorScheme()
	}
}
#endif
