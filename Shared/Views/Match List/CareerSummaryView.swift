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
				.sorted(on: \.name)
			
			LazyVStack(spacing: 20) {
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
		.background(Color(.systemGroupedBackground))
		.navigationTitle("Career Summary")
		.navigationBarTitleDisplayMode(.inline)
	}
	
	struct QueueSection: View {
		let queue: QueueID
		let info: CareerSummary.QueueInfo
		
		@State var isExpanded = false
		
		@Environment(\.assets) private var assets
		
		var body: some View {
			Text(queue.name)
				.font(.title3.weight(.bold))
			
			VStack(spacing: 1) {
				contentSegments()
					.frame(maxWidth: .infinity)
					.background(Color(.tertiarySystemBackground))
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
					.transition(.wipe)
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
				Text("ALL TIME")
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
					
					// I tried using the new inflect API here, but it just slowed stuff down and threw errors
					Text("\(hiddenCount) previous \(hiddenCount > 1 ? "acts" : "act")")
					
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
					HStack {
						VStack {
							let tierInfo = assets?.seasons.tierInfo(number: info.competitiveTier, in: act)
							
							RankInfoView(summary: nil, dataOverride: info)
								.frame(height: 80)
							
							if let tierInfo = tierInfo {
								Text(tierInfo.name)
									.font(.callout.weight(.semibold))
							}
							
							Text("\(info.adjustedRankedRating) RR")
								.font(.caption)
							
							if info.leaderboardRank > 0 {
								leaderboardRankView(rank: info.leaderboardRank, tierInfo: tierInfo)
							}
						}
						.padding()
						
						ActRankView(seasonInfo: info, isIcon: false)
							.frame(height: 200)
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
				Text("\(winCount)/\(gameCount)").fontWeight(.medium)
				+ Text(" games won").foregroundColor(.secondary)
				Spacer()
				Text("\(winPercentage)%")
			}
			.font(.body.monospacedDigit())
		}
		
		func leaderboardRankView(rank: Int, tierInfo: CompetitiveTier?) -> some View {
			ZStack {
				Capsule()
					.fill(tierInfo?.backgroundColor ?? .gray)
				
				let darkeningOpacity = 0.25
				
				Capsule()
					.fill(.black.opacity(darkeningOpacity))
					.blendMode(.plusDarker)
				
				Capsule()
					.fill(.white.opacity(darkeningOpacity))
					.blendMode(.plusLighter)
					.padding(1)
				
				Capsule()
					.fill(.black.opacity(darkeningOpacity))
					.blendMode(.plusDarker)
					.padding(3)
				
				let rankText = Text("Rank \(rank)")
					.font(.callout.weight(.semibold))
					.padding(.horizontal, 4)
					.padding(10)
				
				rankText
					.foregroundColor(.white.opacity(darkeningOpacity))
					.blendMode(.plusLighter)
				
				rankText
					.blendMode(.plusLighter)
			}
			.foregroundColor(.white)
			.fixedSize()
		}
	}
}

private extension AnyTransition {
	static let wipe = modifier(
		active: Modifier(dummyData: 0),
		identity: Modifier(dummyData: 1)
	)
	
	private struct Modifier: ViewModifier {
		let dummyData: Double
		
		func body(content: Content) -> some View {
			content.opacity(1 + dummyData)
		}
	}
}

#if DEBUG
struct CareerSummaryView_Previews: PreviewProvider {
	static var previews: some View {
		CareerSummaryView(summary: PreviewData.summary)
			.withToolbar()
			.inEachColorScheme()
	}
}
#endif
