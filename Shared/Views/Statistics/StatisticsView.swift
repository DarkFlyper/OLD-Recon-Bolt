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
			}
		}
		.navigationTitle("Statistics")
		.buttonBorderShape(.automatic)
	}
	
	func breakdowns(for statistics: Statistics) -> some View {
		Section("Breakdowns") {
			detailsLink("Playtime Breakdown", systemImage: "clock") {
				PlaytimeView(statistics: statistics)
			}
			
			detailsLink("Hit Distribution", systemImage: "scope") {
				HitDistributionView(statistics: statistics)
			}
			
			detailsLink("Win Rate", systemImage: "medal") {
				WinRateView(statistics: statistics)
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
		.font(.title3.weight(.medium))
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
