import SwiftUI
import ValorantAPI

struct CareerSummaryView: View {
	let summary: CareerSummary
	
	private static let queueOrder: [QueueID] = [.competitive, .unrated, .spikeRush, .deathmatch]
	private static let orderedQueues = Set(queueOrder)
	
	var body: some View {
		ScrollView {
			let queues = Self.queueOrder + summary.infoByQueue.keys
				.filter { !Self.orderedQueues.contains($0) }
				.sorted(on: \.rawValue)
			
			VStack(spacing: 20) {
				ForEach(queues, id: \.self) { queue in
					if
						let info = summary.infoByQueue[queue],
						let bySeason = info.bySeason,
						!bySeason.isEmpty
					{
						Spacer()
						
						QueueSection(queue: queue, info: info)
					}
				}
			}
			.padding()
		}
		.background(Color.groupedBackground)
		.navigationTitle("Career Summary")
		.navigationBarTitleDisplayMode(.inline)
	}
	
	struct QueueSection: View {
		let queue: QueueID
		let info: CareerSummary.QueueInfo
		
		@State var isExpanded = false
		
		@Environment(\.assets) private var assets
		
		var body: some View {
			QueueLabel(queue: queue)
				.font(.title3.weight(.bold))
			
			VStack(spacing: 1) {
				contentSegments()
					.frame(maxWidth: .infinity)
					.background(Color.secondaryGroupedBackground)
			}
			.cornerRadius(20)
		}
		
		@ViewBuilder
		func contentSegments() -> some View {
			let acts = assets?.seasons.actsInOrder.reversed() ?? []
			let withActs = acts.compactMap { act in
				info.bySeason?[act.id].map { (act: act, info: $0) }
			}
			
			if let (act, info) = withActs.first {
				summaryCell(for: info, in: act)
			}
			
			let withoutFirst = withActs.dropFirst()
			
			if !withoutFirst.isEmpty {
				expandButton(hiddenCount: withoutFirst.count)
				
				if isExpanded {
					ForEach(withoutFirst, id: \.act.id) { act, info in
						summaryCell(for: info, in: act)
					}
				}
				
				allTimeStatsSegment // only relevant if we have data for more than 1 act
			}
		}
		
		@ViewBuilder
		var allTimeStatsSegment: some View {
			let stats = (info.bySeason ?? [:]).values
				.map { ($0.winCountIncludingPlacements, $0.gameCount) }
			let (winCount, gameCount) = stats
				.reduce((0, 0)) { ($0.0 + $1.0, $0.1 + $1.1) }
			
			VStack {
				Text("ALL TIME", comment: "Career Summary: header for totals of all time")
					.font(.subheadline.weight(.semibold))
					.foregroundStyle(.secondary)
				
				Divider()
				
				winRatioInfo(winCount: winCount, gameCount: gameCount)
			}
			.padding()
		}
		
		func expandButton(hiddenCount: Int) -> some View {
			Button {
				withAnimation {
					isExpanded.toggle()
				}
			} label: {
				HStack {
					Image(systemName: "chevron.down")
						.rotationEffect(.degrees(isExpanded ? 0 : -90))
					
					Text("\(hiddenCount) previous act(s)", comment: "Career Summary: button to show data from previous acts")
					
					Spacer()
				}
				.padding()
			}
			.background(.accentColor.opacity(0.2))
			.tint(.accentColor)
		}
		
		@ViewBuilder
		func summaryCell(for info: CareerSummary.SeasonInfo, in act: Act) -> some View {
			VStack {
				Text(act.nameWithEpisode)
					.font(.subheadline.weight(.semibold))
					.foregroundStyle(.secondary)
				
				Divider().opacity(0.5)
				
				if info.competitiveTier > 0 {
					HStack(spacing: 10) {
						Spacer(minLength: 0)
						
						VStack {
							let tierInfo = assets?.seasons.tiers(in: act).tier(info.competitiveTier)
							
							RankInfoView(summary: nil, dataOverride: info, size: 80)
							
							if let tierInfo {
								Text(tierInfo.name)
									.font(.callout.weight(.semibold))
							}
							
							Text("\(info.adjustedRankedRating) RR")
								.font(.caption)
							
							if info.leaderboardRank > 0 {
								LeaderboardRankView(rank: info.leaderboardRank, tierInfo: tierInfo)
							}
						}
						.fixedSize()
						
						Spacer(minLength: 0)
						
						ExpandableActRankView(seasonInfo: info)
							.frame(height: 200)
							.layoutPriority(1)
						
						Spacer(minLength: 0)
					}
				}
				
				winRatioInfo(winCount: info.winCountIncludingPlacements, gameCount: info.gameCount)
			}
			.padding()
		}
		
		func winRatioInfo(winCount: Int, gameCount: Int) -> some View {
			let fractionWon = Double(winCount) / Double(gameCount)
			let winPercentage = (fractionWon * 100)
				.formatted(FloatingPointFormatStyle().precision(.fractionLength(1)))
			
			return HStack {
				let fraction = Text("\(winCount)/\(gameCount)").fontWeight(.medium)
				Text("\(fraction) games won", comment: "%@ is replaced by a fraction of wins vs. games played, e.g. '5/12 games won'.")
					.foregroundColor(.secondary)
				Spacer()
				Text("\(winPercentage)%", comment: "used throughout the app to format percentages—placeholder is replaced by a number")
			}
			.font(.body.monospacedDigit())
		}
	}
}

struct ExpandableActRankView: View {
	let seasonInfo: CareerSummary.SeasonInfo
	
	@State var isExpanded = false
	
	var body: some View {
		ActRankView(seasonInfo: seasonInfo, isIcon: false, isShowingAllWins: isExpanded)
			.onTapGesture { isExpanded.toggle() }
	}
}

#if DEBUG
struct CareerSummaryView_Previews: PreviewProvider {
	static var previews: some View {
		CareerSummaryView(summary: PreviewData.strangeSummary)
			.withToolbar()
		
		CareerSummaryView(summary: PreviewData.summary)
			.withToolbar()
	}
}
#endif
