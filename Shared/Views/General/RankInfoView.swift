import SwiftUI
import ValorantAPI
import HandyOperators

struct RankInfoView: View {
	let summary: CareerSummary?
	var dataOverride: CareerSummary.SeasonInfo?
	
	var size = 64.0
	var lineWidth = 4.0
	var shouldShowProgress = true
	var shouldFadeUnranked = false
	var shouldFallBackOnPrevious = true
	
	var unit: CGFloat { size / 32 }
	
	@Environment(\.assets) private var assets
	
	var body: some View {
		ZStack {
			if let summary {
				let act = assets?.seasons.currentAct()
				let info = summary.competitiveInfo?.inSeason(act?.id)
				let tier = info?.competitiveTier ?? 0
				let tierInfo = assets?.seasons.tierInfo(number: tier, in: act)
				
				let peakRankInfo: CompetitiveTier? = assets?.seasons.actsInOrder
					.lazy
					.compactMap { act in
						summary.competitiveInfo?.inSeason(act.id)?.peakRank()
					}
					.reversed() // most recent first
					.max()
					.flatMap { assets?.seasons.tierInfo($0) }
				
				if shouldShowProgress {
					progressView(for: tierInfo, rankedRating: info?.adjustedRankedRating ?? 0)
				}
				
				ZStack {
					if shouldFallBackOnPrevious, tier == 0, let peakRankInfo {
						peakRankIcon(using: peakRankInfo)
					} else {
						tierIcon(info: tierInfo)
					}
				}
				.scaleEffect(shouldShowProgress ? 0.7 : 1)
			} else if let info = dataOverride {
				let tierInfo = assets?.seasons.tierInfo(number: info.competitiveTier, in: info.seasonID)
				
				if shouldShowProgress {
					progressView(for: tierInfo, rankedRating: info.adjustedRankedRating)
				}
				
				tierIcon(info: tierInfo)
					.scaleEffect(shouldShowProgress ? 0.7 : 1)
			} else {
				let thickerWidth = lineWidth * 1.5
				
				ZStack {
					Circle().foregroundColor(.black)
					Circle().strokeBorder(.white)
				}
				.opacity(0.1)
				.padding(-0.5 * thickerWidth)
			}
		}
		.padding(lineWidth)
		.frame(width: size, height: size)
	}
	
	func tierIcon(info: CompetitiveTier?) -> some View {
		CompetitiveTierImage(tierInfo: info)
			.opacity(shouldFadeUnranked && info?.number == 0 ? 0.5 : 1)
			.dynamicallyStroked(radius: unit, color: .white.opacity(0.5), blendMode: .plusLighter, avoidClipping: true)
			.shadow(color: .black.opacity(0.2), radius: 2 * unit, x: 0, y: 2 * unit)
	}
	
	@ViewBuilder
	func progressView(for tierInfo: CompetitiveTier?, rankedRating: Int) -> some View {
		let darkening = 0.25
		
		CircularProgressView(lineWidth: lineWidth) {
			CircularProgressLayer(
				end: CGFloat(rankedRating) / 100,
				shouldKnockOutSurroundings: true,
				color: .white, opacity: 0.5, blendMode: .plusLighter
			)
		} base: {
			Color.white.opacity(darkening).blendMode(.plusLighter)
		} background: {
			ZStack {
				tierInfo?.backgroundColor
				Color.black.opacity(darkening).blendMode(.plusDarker)
			}
		}
	}
	
	@ViewBuilder
	func peakRankIcon(using info: CompetitiveTier) -> some View {
		// perceptual centering
		VStack {
			info.rankTriangleUpwards?.view(shouldLoadImmediately: true)
			Spacer(minLength: 0)
		}
		.aspectRatio(shouldShowProgress ? 0.85 : 1.0, contentMode: .fit)
		.shadow(color: .black.opacity(0.2), radius: 2 * unit, x: 0, y: 2 * unit)
		.overlay {
			VStack {
				Spacer(minLength: 0)
				Image(systemName: "clock")
					.resizable()
					.aspectRatio(contentMode: .fit)
			}
			.aspectRatio(0.33, contentMode: .fit) // align with the bottom of the triangle (when there's no progress shown)
			.font(.body.bold())
			.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
			.foregroundColor(.white)
			.shadow(color: .black.opacity(0.5), radius: 2 * unit, x: 0, y: 1 * unit)
		}
	}
}

#if DEBUG
struct RankInfoView_Previews: PreviewProvider, PreviewProviderWithAssets {
	static func previews(assets: AssetCollection) -> some View {
		let act = assets.seasons.currentAct()!
		let def = CareerSummary.SeasonInfo(seasonID: act.id)
		let ranks = assets.seasons.competitiveTiers[act.competitiveTiers]!
		
		func summary(forTier tier: Int) -> CareerSummary {
			PreviewData.summary <- {
				$0.competitiveInfo!.bySeason![act.id, default: def]
					.competitiveTier = tier
			}
		}
		
		let basicSummary = summary(forTier: 19) <- {
			$0.competitiveInfo!.bySeason![act.id]!.rankedRating = 69
		}
		
		return Group {
			VStack {
				RankInfoView(summary: basicSummary, shouldShowProgress: false)
				RankInfoView(summary: basicSummary <- { $0.infoByQueue = [:] })
				RankInfoView(summary: summary(forTier: 0), shouldFallBackOnPrevious: false)
				RankInfoView(summary: summary(forTier: 0), shouldFallBackOnPrevious: true)
				RankInfoView(summary: basicSummary)
				RankInfoView(summary: nil)
				
				Group {
					RankInfoView(summary: summary(forTier: 19), shouldShowProgress: false, shouldFallBackOnPrevious: true)
					RankInfoView(summary: summary(forTier: 0), shouldShowProgress: false, shouldFallBackOnPrevious: true)
				}
				.padding(.horizontal, 64)
				.background(Color.primary.opacity(0.2))
			}
			.fixedSize(horizontal: false, vertical: true)
			
			VStack {
				ForEach([32.0, 64, 96, 128], id: \.self) { size in
					HStack {
						RankInfoView(summary: basicSummary, size: size)
						RankInfoView(summary: basicSummary, size: size, shouldShowProgress: false)
						RankInfoView(summary: summary(forTier: 0), size: size, shouldShowProgress: false)
						RankInfoView(summary: summary(forTier: 0), size: size)
					}
					.background(Color.primary.opacity(0.1))
				}
			}
			
			RankInfoView(summary: summary(forTier: 0))
				.frame(height: 64)
			
			RankInfoView(summary: basicSummary, lineWidth: 8)
				.frame(width: 128, height: 128)
			
			LazyHGrid(rows: [.init(), .init(), .init()], spacing: 20) {
				ForEach(ranks.tiers.values.map(\.number).sorted(), id: \.self) {
					// this would be equivalent, but i want to test this overload too
					//RankInfoView(summary: summary(forTier: $0), shouldFallBackOnPrevious: false)
					RankInfoView(summary: nil, dataOverride: .init(
						seasonID: act.id,
						actRank: $0,
						competitiveTier: $0,
						rankedRating: 69
					))
				}
				.frame(width: 64)
			}
			.padding()
			.frame(height: 250)
		}
		.previewLayout(.sizeThatFits)
		.environmentObject(ImageManager())
	}
}
#endif
