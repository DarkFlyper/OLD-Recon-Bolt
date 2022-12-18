import SwiftUI
import WidgetKit
import Intents
import ValorantAPI
import HandyOperators
import CGeometry

struct ViewMissionsWidget: Widget {
	var body: some WidgetConfiguration {
		IntentConfiguration(
			kind: "view missions",
			intent: ViewMissionsIntent.self,
			provider: ContractsEntryProvider()
		) { entry in
			MissionListView(entry: entry)
		}
		.supportedFamilies([.systemMedium, .systemLarge])
		.configurationDisplayName("Missions")
		.description("Check your progress on daily & weekly missions.")
	}
}

struct MissionListView: TimelineEntryView {
	var entry: ContractsEntryProvider.Entry
	
	@Environment(\.widgetFamily) private var widgetFamily
	
	func contents(for value: ContractDetailsInfo) -> some View {
		let dailies = value.missions.filter { $0.info?.type == .daily }
		let weeklies = value.missions.filter { $0.info?.type == .weekly }
		
		HStack(spacing: 0) {
			Spacer()
			
			CurrentMissionsList(
				title: "Dailies",
				missions: dailies,
				countdownTarget: dailies.firstNonNil(\.mission.expirationTime)
			)
			
			Spacer()
			
			CurrentMissionsList(
				title: "Weeklies",
				missions: weeklies,
				countdownTarget: value.contractDetails.missionMetadata.weeklyRefillTime
			)
			
			Spacer()
		}
		.frame(maxHeight: .infinity)
		.background(Color.groupedBackground)
	}
}

struct CurrentMissionsList: View {
	var title: String
	var missions: [MissionWithInfo]
	var assets: AssetCollection?
	var countdownTarget: Date? = nil
	
	var body: some View {
		if !missions.isEmpty {
			VStack(spacing: 8) {
				HStack(alignment: .lastTextBaseline) {
					Text(title)
						.font(.headline)
						.multilineTextAlignment(.leading)
					
					Spacer()
					
					Group {
						if let countdownTarget {
							HourlyCountdownText(target: countdownTarget)
							//Image(systemName: "clock")
						}
					}
					.font(.caption.weight(.medium))
					.foregroundStyle(.secondary)
				}
				
				HStack(alignment: .top, spacing: 16) {
					ForEach(missions, id: \.mission.id) { mission, missionInfo in
						if let missionInfo {
							MissionView(missionInfo: missionInfo, mission: mission, assets: assets)
						} else {
							Image(systemName: "questionmark")
								.foregroundStyle(.secondary)
						}
					}
				}
				.padding()
				.background(Color.secondaryGroupedBackground)
				.cornerRadius(8)
			}
			.fixedSize()
		}
	}
}

struct MissionView: View {
	var missionInfo: MissionInfo
	var mission: Mission?
	var assets: AssetCollection?
	
	@Environment(\.widgetFamily) private var widgetFamily
	
	var body: some View {
		let resolved = ResolvedMission(info: missionInfo, mission: mission, assets: assets)
		let isComplete = mission?.isComplete == true
		
		VStack(spacing: 8) {
			if false, widgetFamily != .systemSmall {
				Text(resolved.name)
					.font(.system(size: 8))
					.opacity(isComplete ? 0.5 : 1)
					.lineLimit(2)
					.multilineTextAlignment(.center)
					.frame(width: 48)
					.frame(width: 0)
			}
			
			ZStack {
				if !isComplete, let progress = resolved.progress {
					VStack(spacing: 4) {
						let fractionComplete = CGFloat(progress) / CGFloat(resolved.toComplete)
						CircularProgressView {
							CircularProgressLayer(end: fractionComplete, color: .accentColor)
						} base: {
							Color.tertiaryGroupedBackground
						}
					}
				} else {
					Circle()
						.stroke(lineWidth: 2)
						.foregroundColor(isComplete ? .accentColor : .gray.opacity(0.1))
				}
				
				if isComplete {
					Image(systemName: "checkmark")
				}
			}
			.frame(width: 32, height: 32)
			.foregroundColor(.accentColor)
			
			if false, !isComplete, let progress = resolved.progress {
				VStack {
					Text("\(progress)")
					Text("\(resolved.toComplete)")
				}
				.font(.caption)
				.foregroundStyle(.secondary)
				.fixedSize()
				.frame(width: 0) // fake narrower width
			}
		}
	}
	
	// had to extract this because compile times exploded with this logic in a function builder
	struct ResolvedMission {
		var name: String
		var progress: Int?
		var toComplete: Int
		
		init(info: MissionInfo, mission: Mission?, assets: AssetCollection?) {
			let (objectiveID, progress) = mission?.objectiveProgress.singleElement ?? (nil, nil)
			self.progress = progress
			let objectiveValue = info.objective(id: objectiveID)
			self.toComplete = objectiveValue?.value
			?? info.progressToComplete // this is incorrect for e.g. the "you or your allies plant or defuse spikes" one, where it's 1 while the objectives correctly list it as 5
			
			let objective = (objectiveID ?? objectiveValue?.objectiveID)
				.flatMap { assets?.objectives[$0] }
			
			self.name = objective?.directive?
				.valorantLocalized(number: toComplete)
			?? info.displayName
			?? info.title
			?? "<Unnamed Mission>"
		}
	}
}

struct HourlyCountdownText: View {
	var target: Date
	
	@Environment(\.timeOverride) var timeOverride
	
	var body: some View {
		let now = timeOverride ?? .now
		if target < now {
			Text("old")
		} else {
			let delta = now.addingTimeInterval(-3599)..<target // "round up" the hour, lol
			Text("< \(delta, format: .components(style: .condensedAbbreviated, fields: [.day, .hour]))")
		}
	}
}

extension EnvironmentValues {
	var timeOverride: Date? {
		get { self[Key.self] }
		set { self[Key.self] = newValue }
	}
	
	private enum Key: EnvironmentKey {
		static let defaultValue: Date? = nil
	}
}

struct ViewMissionsWidget_Previews: PreviewProvider {
	static var previews: some View {
		if let assets = AssetManager().assets {
			MissionListView(entry: .init(
				info: .success(.init(
					contractDetails: PreviewData.contractDetails,
					missions: PreviewData.contractDetails.missions.map { ($0, assets.missions[$0.id]) },
					assets: assets
				)),
				configuration: .init() <- { _ in
					//$0.accentColor = .unknown
				}
			))
			.previewContext(WidgetPreviewContext(family: .systemMedium))
			.environment(\.timeOverride, Calendar.current.date(from: DateComponents(
				year: 2022, month: 11, day: 02, hour: 02, minute: 30, second: 00
			))!)
		} else {
			Text("oh no")
				.previewContext(WidgetPreviewContext(family: .systemMedium))
		}
	}
}
