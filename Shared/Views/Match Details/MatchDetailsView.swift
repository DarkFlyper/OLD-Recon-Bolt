import SwiftUI
import ValorantAPI
import HandyOperators

struct MatchDetailsView: View {
	let data: MatchViewData
	@State var highlight = PlayerHighlightInfo()
	
	private static let startDateFormatter = DateFormatter() <- {
		$0.dateStyle = .short
	}
	private static let startTimeFormatter = DateFormatter() <- {
		$0.timeStyle = .short
	}
	private static let gameLengthFormatter = DateComponentsFormatter() <- {
		$0.unitsStyle = .abbreviated
		$0.allowedUnits = [.hour, .minute, .second]
	}
	
	var body: some View {
		ScrollView {
			VStack(spacing: 20) {
				MatchDetailsHero(data: data)
					.edgesIgnoringSafeArea(.horizontal)
				
				HStack {
					let matchInfo = data.details.matchInfo
					
					Text(matchInfo.gameStart, formatter: Self.startDateFormatter)
					Text(matchInfo.gameStart, formatter: Self.startTimeFormatter)
						.foregroundColor(.secondary)
					
					Spacer()
					
					Text(Self.gameLengthFormatter.string(from: matchInfo.gameLength)!)
					
				}
				.padding(.horizontal)
				
				Divider().padding(.horizontal)
				
				ScoreboardView(data: data, highlight: $highlight)
				
				if KillBreakdownView.canDisplay(for: data) {
					Divider().padding(.horizontal)
					
					KillBreakdownView(data: data, highlight: $highlight)
					
					VStack(alignment: .leading, spacing: 8) {
						NavigationLink {
							RoundInfoContainer(matchData: data, roundNumber: 0)
						} label: {
							HStack {
								Text("Details by Round", comment: "Match Details: button to view details by round")
								Image(systemName: "chevron.forward")
							}
						}
						
						Text("You can also tap a round's number in the kill breakdown above to quickly view its details.", comment: "Match Details: footnote")
							.font(.footnote)
							.foregroundColor(.secondary)
					}
					.frame(maxWidth: .infinity, alignment: .leading)
					.padding(.horizontal)
				}
			}
			.padding(.bottom)
		}
	}
}

#if DEBUG
struct MatchDetailsView_Previews: PreviewProvider {
	static var previews: some View {
		MatchDetailsView(
			data: PreviewData.singleMatchData
		)
		.navigationTitle("Match Details")
		.withToolbar(allowLargeTitles: false)
	}
}
#endif
