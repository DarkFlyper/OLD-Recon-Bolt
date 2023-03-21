import SwiftUI
import ValorantAPI

@available(iOS 16.0, *)
struct StatisticsView: View {
	var user: User
	var matchList: MatchList
	
	@State var statistics: Statistics?
	
	@Environment(\.assets) private var assets
	@Environment(\.isIncognito) private var isIncognito
	
	var body: some View {
		Form {
			LoadingSection(matchList: matchList, statistics: $statistics)
			
			// TODO: filter!
			
			if let statistics {
				breakdowns(for: statistics)
					.font(.title3.weight(.medium))
			}
		}
		.navigationTitle("Statistics")
		.buttonBorderShape(.automatic)
	}
	
	@ViewBuilder
	func breakdowns(for statistics: Statistics) -> some View {
		// TODO: more overview charts!
		
		Section {
			detailsLink("Playtime Breakdown", systemImage: "clock") {
				PlaytimeView(statistics: statistics)
			}
		}
		
		Section {
			detailsLink("Hit Distribution", systemImage: "scope") {
				HitDistributionView(statistics: statistics)
			}
		}
		
		Section {
			TransparentNavigationLink {
				WinRateView(statistics: statistics)
			} label: {
				VStack(alignment: .leading) {
					Label("Win Rate", systemImage: "medal")
						.padding(.vertical, 8)
					
					WinRateView.ChartOverTime.overview(statistics: statistics)?
						.chartLegend(.hidden)
						.chartXAxis(.hidden)
						.chartYAxis(.hidden)
						.overlay(alignment: .bottom) {
							Color.primary.opacity(0.1).frame(height: 1)
						}
				}
			}
		}
	}
	
	func detailsLink<Destination: View>(
		_ title: LocalizedStringKey, systemImage: String,
		@ViewBuilder destination: @escaping () -> Destination
	) -> some View {
		TransparentNavigationLink(destination: destination) {
			Label(title, systemImage: systemImage)
		}
		.padding(.vertical, 8)
	}
}

#if DEBUG
@available(iOS 16.0, *)
struct StatisticsView_Previews: PreviewProvider {
	static var previews: some View {
		StatisticsView(
			user: PreviewData.user, matchList: PreviewData.matchList,
			statistics: PreviewData.statistics
		)
		.withToolbar()
	}
}
#endif
