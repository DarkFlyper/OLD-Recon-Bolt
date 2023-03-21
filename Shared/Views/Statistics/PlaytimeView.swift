import SwiftUI

@available(iOS 16.0, *)
struct PlaytimeView: View {
	var statistics: Statistics
	
	var playtime: Statistics.Playtime { statistics.playtime }
	
	var body: some View {
		List {
			// TODO: breakdown by day/week/month as chart
			
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
	
	func durationRow<Label: View>(duration: TimeInterval, @ViewBuilder label: () -> Label) -> some View {
		Stats.LabeledRow(label: label) {
			Stats.DurationLabel(duration: duration)
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
