import SwiftUI
import WidgetKit
import Intents
import ValorantAPI
import HandyOperators
import CGeometry

struct ViewMissionsWidget: Widget {
	var body: some WidgetConfiguration {
		IntentConfiguration(
			kind: WidgetKind.viewMissions.rawValue,
			intent: ViewMissionsIntent.self,
			provider: ContractsEntryProvider()
		) { entry in
			MissionListView(entry: entry)
				.reloadingOnTap(.viewMissions)
		}
		.supportedFamilies([.systemMedium])
		.configurationDisplayName(Text("Missions", comment: "Missions Widget: title"))
		.description(Text("Check your progress on daily & weekly missions.", comment: "Missions Widget: description"))
	}
}

struct MissionListView: TimelineEntryView {
	var entry: ContractsEntryProvider.Entry
	
	func contents(for value: ContractDetailsInfo) -> some View {
		let contracts = value.contracts
		Grid {
			Box(
				title: Text("Daily", comment: "Missions Widget"),
				countdownTarget: contracts.dailyRefresh
			) {
				DailyTicketView(milestones: contracts.daily.milestones)
					.padding()
					.background(Color.secondaryGroupedBackground)
					.cornerRadius(8)
			}
			
			Spacer()
			
			Box(
				title: Text("Weekly", comment: "Missions Widget"),
				countdownTarget: contracts.weeklyRefresh
			) {
				weeklyContents(contracts: contracts)
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.padding()
		.background(Color.groupedBackground)
	}
	
	@ViewBuilder
	func weeklyContents(contracts: ResolvedContracts) -> some View {
		let expectedCount = 3
		
		HStack(spacing: 1) {
			HStack(alignment: .top, spacing: 16) {
				if !contracts.weeklies.isEmpty {
					ForEach(contracts.weeklies) { mission in
						if let info = mission.info {
							MissionView(missionInfo: info, mission: mission.mission)
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
			
			if let queued = contracts.queuedUpWeeklies {
				Text("+\(queued.count) queued", comment: "Missions Widget: how many more weeklies are queued up after the current set")
					.font(.footnote)
					.foregroundStyle(.secondary)
					.padding(8)
					.background {
						RoundedRectangle(cornerRadius: 8)
							.fill(Color.secondaryGroupedBackground)
							.padding(.leading, -8)
							.clipped()
					}
			}
		}
	}
	
	private struct Box<Content: View>: View {
		var title: Text
		let countdownTarget: Date?
		@ViewBuilder var content: Content
		
		var body: some View {
			GridRow {
				VStack(alignment: .trailing) {
					title
						.font(.headline)
					
					Group {
						if let countdownTarget {
							HourlyCountdownText(target: countdownTarget)
						}
					}
					.font(.caption.weight(.medium))
					.foregroundStyle(.secondary)
				}
				.gridColumnAlignment(.trailing)
				
				content
					.gridColumnAlignment(.leading)
			}
		}
	}
}

/*
extension View {
	@ViewBuilder
	func withWidgetBackground() -> some View {
		if #available(iOSApplicationExtension 17.0, *) {
			containerBackground(.background, for: .widget)
		} else {
			self
		}
	}
}
 */

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
				if isComplete {
					Circle()
						.fill(.accentColor)
				} else if let (progress, toComplete) = progress {
					VStack(spacing: 4) {
						let fractionComplete = CGFloat(progress) / CGFloat(toComplete)
						CircularProgressView {
							CircularProgressLayer(end: fractionComplete, color: .accentColor)
						} base: {
							Rectangle()
								.foregroundStyle(.faded)
						}
					}
				} else {
					Circle()
						.stroke(.accentColor, lineWidth: 2)
				}
				
				if isComplete {
					Image(systemName: "checkmark")
						.foregroundColor(.white)
				}
			}
			.frame(width: 32, height: 32)
		}
	}
}

private struct HourlyCountdownText: View {
	var target: Date
	
	@Environment(\.timeOverride) var timeOverride
	
	var body: some View {
		let now = timeOverride ?? .now
		if target < now {
			Text(
				"old",
				comment: "Missions Widget: countdown label when the target is in the past. Should never really show up, since at this point there's new data."
			)
		} else {
			let delta = now.addingTimeInterval(-3599)..<target // "round up" the hour, lol
			Text(
				"< \(delta, format: .components(style: .condensedAbbreviated, fields: [.day, .hour]))",
				comment: "Missions Widget: countdown label when the target is in the future. e.g. '< 2d 3h'"
			)
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
		if AssetManager().assets != nil {
			MissionListView(entry: .mocked(
				value: .init(
					contracts: PreviewData.resolvedContracts <- {
						$0.dailyRefresh = .init(timeIntervalSinceNow: 12345)
					}
				),
				configuration: .init() <- { _ in
					//$0.accentColor = .unknown
				}
			))
			.previewContext(WidgetPreviewContext(family: .systemMedium))
			.environment(\.timeOverride, Calendar.current.date(from: DateComponents(
				year: 2022, month: 11, day: 02, hour: 02, minute: 30, second: 00
			))!)
		} else {
			Text("oh no" as String)
				.previewContext(WidgetPreviewContext(family: .systemMedium))
		}
	}
}
#endif
