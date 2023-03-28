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
		.supportedFamilies([.systemSmall, .systemMedium])
		.configurationDisplayName("Missions")
		.description("Check your progress on daily & weekly missions.")
	}
}

struct MissionListView: TimelineEntryView {
	var entry: ContractsEntryProvider.Entry
	
	@Environment(\.adjustedWidgetFamily) private var widgetFamily
	
	func contents(for value: ContractDetailsInfo) -> some View {
		let contracts = value.contracts
		HStack(alignment: .top, spacing: 0) {
			Spacer()
			
			CurrentMissionsList(
				title: "Daily", expectedCount: 2,
				missions: contracts.dailies,
				countdownTarget: contracts.dailyRefresh
			)
			
			Spacer()
			
			if widgetFamily != .systemSmall {
				CurrentMissionsList(
					title: "Weekly", expectedCount: 3,
					missions: contracts.weeklies,
					countdownTarget: contracts.weeklyRefresh,
					supplement: contracts.queuedUpWeeklies.map { "+\($0.count) queued" }
				)
				
				Spacer()
			}
		}
		.frame(maxHeight: .infinity)
		.background(Color.groupedBackground)
	}
}

struct CurrentMissionsList: View {
	var title: LocalizedStringKey
	var expectedCount: Int
	var missions: [MissionWithInfo]
	var countdownTarget: Date? = nil
	var supplement: LocalizedStringKey? = nil
	
	var body: some View {
		VStack(spacing: 8) {
			HStack(alignment: .lastTextBaseline) {
				Text(title)
					.font(.headline)
					.multilineTextAlignment(.leading)
				
				Spacer()
				
				Group {
					if let countdownTarget {
						HourlyCountdownText(target: countdownTarget)
					}
				}
				.font(.caption.weight(.medium))
				.foregroundStyle(.secondary)
			}
			.padding(.horizontal, 4)
			
			VStack(spacing: 1) {
				HStack(alignment: .top, spacing: 16) {
					if !missions.isEmpty {
						ForEach(missions, id: \.mission.id) { mission, missionInfo in
							if let missionInfo {
								MissionView(missionInfo: missionInfo, mission: mission)
							} else {
								Image(systemName: "questionmark")
									.foregroundStyle(.secondary)
							}
						}
					} else {
						ForEach(0..<expectedCount, id: \.self) { _ in
							MissionView.ProgressView(isComplete: true)
						}
					}
				}
				.padding()
				.background(Color.secondaryGroupedBackground)
				.cornerRadius(8)
				
				if let supplement {
					Text(supplement)
						.font(.footnote)
						.foregroundStyle(.secondary)
						.padding(.horizontal, 8)
						.padding(.vertical, 6)
						.padding(.top, -2)
						.background {
							RoundedRectangle(cornerRadius: 8)
								.fill(Color.secondaryGroupedBackground)
								.padding(.top, -8)
								.clipped()
						}
				}
			}
		}
		.fixedSize()
	}
}

struct MissionView: View {
	var missionInfo: MissionInfo
	var mission: Mission?
	
	@Environment(\.assets) private var assets
	
	var body: some View {
		let resolved = ResolvedMission(info: missionInfo, mission: mission, assets: assets)
		
		ProgressView(
			isComplete: mission?.isComplete == true,
			progress: resolved.progress.map { ($0, resolved.toComplete) }
		)
	}
	
	struct ProgressView: View {
		var isComplete: Bool
		var progress: (Int, Int)?
		
		var body: some View {
			ZStack {
				if !isComplete, let (progress, toComplete) = progress {
					VStack(spacing: 4) {
						let fractionComplete = CGFloat(progress) / CGFloat(toComplete)
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

#if DEBUG
struct ViewMissionsWidget_Previews: PreviewProvider {
	static var previews: some View {
		if let assets = AssetManager().assets {
			MissionListView(entry: .init(
				info: .success(.init(
					contracts: .init(details: PreviewData.contractDetails, assets: assets, config: PreviewData.gameConfig)
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
#endif
