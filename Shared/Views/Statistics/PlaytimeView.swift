import SwiftUI
import Charts

@available(iOS 16.0, *)
struct PlaytimeView: View {
	var statistics: Statistics
	
	var playtime: Statistics.Playtime { statistics.playtime }
	
	var body: some View {
		List {
			Section("Over Time") {
				chartOverTime()
			}
			
			Section("Overall") {
				durationRow(duration: playtime.total) {
					Text("Total Playtime")
				}
			}
			
			Section("By Queue") {
				ForEach(playtime.byQueue.sorted(on: \.value).reversed(), id: \.key) { queue, time in
					durationRow(duration: time) {
						GameModeImage(id: statistics.modeByQueue[queue]!)
							.frame(height: 24)
						QueueLabel(queue: queue ?? .custom)
					}
				}
			}
			
			if !playtime.byPremade.isEmpty {
				Section("By Premade Teammate") {
					ForEach(playtime.byPremade.sorted(on: \.value).reversed(), id: \.key) { teammate, time in
						TransparentNavigationLink {
							MatchListView(userID: teammate)
						} label: {
							durationRow(duration: time) {
								UserLabel(userID: teammate)
							}
						}
					}
				}
			}
		}
		.navigationTitle("Playtime")
	}
	
	@State var timeGrouping = DateBinSize.day
	
	@ViewBuilder
	func chartOverTime() -> some View {
		ChartOverTime(statistics: statistics, timeGrouping: timeGrouping)
			.aligningListRowSeparator()
			.padding(.vertical)
		
		Picker("Group by", selection: $timeGrouping) {
			ForEach(DateBinSize.allCases) { size in
				Text(size.name).tag(size)
			}
		}
	}
	
	func durationRow<Label: View>(duration: TimeInterval, @ViewBuilder label: () -> Label) -> some View {
		Stats.LabeledRow(label: label) {
			Stats.DurationLabel(duration: duration)
		}
	}
	
	static func overview(statistics: Statistics) -> ChartOverTime? {
		guard let first = statistics.matches.first, let last = statistics.matches.last else { return nil }
		let range = last.matchInfo.gameStart..<first.matchInfo.gameStart
		return .init(
			statistics: statistics,
			timeGrouping: .smallestThatFits(range)
		)
	}
	
	struct ChartOverTime: View {
		var statistics: Statistics
		var timeGrouping: DateBinSize
		
		var body: some View {
			Chart(statistics.matches) { match in
				BarMark(
					x: .value("Day", match.matchInfo.gameStart, unit: timeGrouping.component),
					y: .value("Playtime", match.matchInfo.gameLength / 3600)
				)
				.foregroundStyle(Color.valorantRed)
			}
			.chartYAxis {
				// .stride(by: .hour) just left me with empty content for some reason, so now i'm just quantizing to hours first
				AxisMarks { value in
					AxisValueLabel {
						let duration = Duration.seconds(3600 * value.as(TimeInterval.self)!)
						Text(duration, format: .units(allowed: [.hours, .minutes], width: .narrow))
					}
					AxisTick()
					AxisGridLine()
				}
			}
		}
	}
}

#if DEBUG
@available(iOS 16.0, *)
struct PlaytimeView_Previews: PreviewProvider {
    static var previews: some View {
		PlaytimeView(statistics: PreviewData.statistics)
			.withToolbar()
    }
}
#endif
