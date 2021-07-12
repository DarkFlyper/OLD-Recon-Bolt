import SwiftUI
import SwiftUIMissingPieces
import HandyOperators
import ValorantAPI

struct MatchCell: View {
	static let dateFormatter = DateFormatter() <- {
		$0.dateStyle = .short
	}
	static let timeFormatter = DateFormatter() <- {
		$0.timeStyle = .short
	}
	
	let match: CompetitiveUpdate
	let userID: User.ID
	
	@State var matchDetails: MatchDetails?
	
	var body: some View {
		ZStack {
			NavigationLink(
				destination: MatchDetailsContainer(matchID: match.id, userID: userID),
				label: { EmptyView() }
			)
			.opacity(0) // hide disclosure indicator and avoid accent color changes
			
			HStack {
				VStack(alignment: .leading) {
					matchInfo
				}
				
				if match.isRanked {
					changeInfo
				}
			}
		}
		.padding(.vertical, 8)
		.id(match.id)
		.withLocalData($matchDetails) { $0.matchDetails(for: match.id) }
	}
	
	private var changeInfo: some View {
		HStack {
			VStack(alignment: .trailing) {
				Group {
					if match.performanceBonus != 0 {
						Text("WP: +\(match.performanceBonus)")
							.foregroundColor(.green)
					}
					if match.afkPenalty != 0 {
						Text("AFK: \(match.afkPenalty)")
							.foregroundColor(.red)
					}
				}
				.font(.caption)
				
				let eloChange = match.ratingEarned
				Text(eloChange > 0 ? "+\(eloChange)" : eloChange < 0 ? "\(eloChange)" : "=")
					.foregroundColor(changeColor)
				
				Text("\(match.tierProgressAfterUpdate)")
					.foregroundColor(.gray)
			}
			.frame(minWidth: 50, alignment: .trailing)
			
			ChangeRing(match: match)
				.frame(height: 64)
				.accentColor(changeColor)
		}
		.font(.callout.monospacedDigit())
	}
	
	@ViewBuilder
	private var matchInfo: some View {
		VStack {
			HStack {
				Text(Self.dateFormatter.string(from: match.startTime))
					.foregroundStyle(.primary)
					.fixedSize()
				Text(Self.timeFormatter.string(from: match.startTime))
					.foregroundStyle(.secondary)
			}
			.font(.caption)
			
			ZStack {
				if let matchDetails = matchDetails {
					HStack {
						GameModeImage(id: matchDetails.matchInfo.gameMode)
							.frame(height: 20)
						
						Text(matchDetails.matchInfo.queueID.name)
							.foregroundStyle(.secondary)
							.padding(.top, -2) // small caps are shorter
					}
				} else {
					MapImage.LabelText(mapID: match.mapID)
						.fixedSize()
						.padding(.top, -2) // small caps are shorter
				}
			}
			.font(.callout.bold().smallCaps())
			.foregroundStyle(.regularMaterial)
			.colorScheme(.light)
			.shadow(color: .black, radius: 2, y: 1)
			.padding(4)
			.padding(.horizontal, 2)
			.frame(maxWidth: .infinity, alignment: .leading)
			.background {
				MapImage.splash(match.mapID)
					.scaledToFill()
					.frame(maxWidth: .infinity)
					.clipped()
			}
			.mask(Capsule())
			
			detailsInfo
				.font(.caption)
				.frame(maxWidth: .infinity)
		}
	}
	
	@ViewBuilder
	private var detailsInfo: some View {
		if let matchDetails = matchDetails {
			let myself = matchDetails.players.first { $0.id == userID }!
			
			VStack {
				ScoreSummaryView(
					teams: matchDetails.teams,
					ownTeamID: myself.teamID
				)
				.font(.body.weight(.semibold))
				
				KDASummaryView(player: myself)
					.foregroundStyle(.secondary, .tertiary)
			}
		}
	}
	
	private var changeColor: Color {
		match.ratingEarned > 0 ? .green : match.ratingEarned < 0 ? .red : .gray
	}
}

private struct ChangeRing: View {
	let match: CompetitiveUpdate
	
	var body: some View {
		ZStack {
			let before = CGFloat(match.eloBeforeUpdate) / 100
			let after = CGFloat(match.eloAfterUpdate) / 100
			let lower = min(before, after)
			let higher = max(before, after)
			let zeroPoint = lower.rounded(.down)
			
			CircularProgressView(
				base: { Color.gray.opacity(0.2) },
				layers: {
					CircularProgressLayer(
						end: after - zeroPoint,
						color: .gray
					)
					CircularProgressLayer(
						start: lower - zeroPoint,
						end: higher - zeroPoint,
						shouldKnockOutSurroundings: true,
						color: .accentColor
					)
				}
			)
			
			CompetitiveTierImage(tier: match.tierAfterUpdate, time: match.startTime)
				.padding(8)
			
			movementIndicator
				.background(Circle().fill(Color.white).blendMode(.destinationOut))
				.alignmentGuide(.top) { $0[VerticalAlignment.center] }
				.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
		}
		.compositingGroup()
		.padding(2)
		.aspectRatio(contentMode: .fit)
	}
	
	@ViewBuilder
	private var movementIndicator: some View {
		Group {
			if match.tierAfterUpdate > match.tierBeforeUpdate {
				// promotion
				Image(systemName: "chevron.up.circle.fill")
					.foregroundColor(.green)
			} else if match.tierAfterUpdate < match.tierBeforeUpdate {
				// demotion
				Image(systemName: "chevron.down.circle.fill")
					.foregroundColor(.red)
			}
		}
		.font(.system(size: 12))
	}
}

#if DEBUG
struct MatchCell_Previews: PreviewProvider {
	static let demotion = CompetitiveUpdate.example(tierChange: (6, 5), tierProgressChange: (10, 80), index: 0)
		<- { $0.afkPenalty = -7 }
	static let decrease = CompetitiveUpdate.example(tierChange: (8, 8), tierProgressChange: (60, 40), index: 1)
	static let unchanged = CompetitiveUpdate.example(tierChange: (12, 12), tierProgressChange: (50, 50), index: 2)
	static let increase = CompetitiveUpdate.example(tierChange: (8, 8), tierProgressChange: (40, 60), index: 3)
	static let promotion = CompetitiveUpdate.example(tierChange: (20, 21), tierProgressChange: (80, 10), index: 4) <- {
		$0.afkPenalty = -3
		$0.performanceBonus = 11
	}
	
	static let unranked = CompetitiveUpdate.example(tierChange: (0, 0), tierProgressChange: (0, 0), index: 5)
	
	static let jump = CompetitiveUpdate.example(tierChange: (11, 13), tierProgressChange: (90, 30), index: 6)
		<- { $0.performanceBonus = 14 }
	
	static let withinImmortal = CompetitiveUpdate.example(tierChange: (21, 21), tierProgressChange: (290, 310))
	static let promotionToRadiant = CompetitiveUpdate.example(tierChange: (21, 24), tierProgressChange: (379, 400), ratingEarned: 21)
	
	static let allExamples = [
		demotion, decrease, unchanged, increase, promotion,
		unranked, jump, withinImmortal, promotionToRadiant,
	]
	
	static var previews: some View {
		List {
			MatchCell(
				match: allExamples.first! <- { $0.id = PreviewData.singleMatch.id },
				userID: PreviewData.userID,
				matchDetails: PreviewData.singleMatch
			)
			
			ForEach(allExamples.dropFirst()) {
				MatchCell(match: $0, userID: PreviewData.userID)
			}
		}
		.withToolbar(allowLargeTitles: false) // otherwise NavigationLink grays out accent colors
		.padding(.top, -120) // use all the space
		.inEachColorScheme()
	}
}
#endif
