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
		detailsLink("Playtime Breakdown", systemImage: "clock") {
			PlaytimeView(statistics: statistics)
		} chart: {} // TODO: nice chart?
		
		detailsLink("Hit Distribution", systemImage: "scope") {
			HitDistributionView(statistics: statistics)
		} chart: {
			HitDistributionView.ChartOverTime.overview(statistics: statistics)
		}
		
		detailsLink("Win Rate", systemImage: "medal") {
			WinRateView(statistics: statistics)
		} chart: {
			WinRateView.ChartOverTime.overview(statistics: statistics)?
				.overlay(alignment: .bottom) {
					Color.primary.opacity(0.1).frame(height: 1)
				}
		}
	}
	
	func detailsLink<Destination: View, Chart: View>(
		_ title: LocalizedStringKey, systemImage: String,
		@ViewBuilder destination: @escaping () -> Destination,
		@ViewBuilder chart: @escaping () -> Chart
	) -> some View {
		Group {
			TransparentNavigationLink(destination: destination) {
				VStack(alignment: .leading) {
					Label(title, systemImage: systemImage)
					
					chart()
						.chartLegend(.hidden)
						.chartXAxis(.hidden)
						.chartYAxis(.hidden)
				}
				.padding(.vertical, 8)
			}
		}
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
