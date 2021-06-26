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
	
	private let visualsHeight: CGFloat = 64
	
	let match: CompetitiveUpdate
	let userID: User.ID
	
	var body: some View {
		NavigationLink(
			destination: MatchDetailsContainer(matchID: match.id, userID: userID)
		) {
			HStack {
				mapIcon
				
				VStack(alignment: .leading) {
					Text(Self.dateFormatter.string(from: match.startTime))
					Text(Self.timeFormatter.string(from: match.startTime))
						.foregroundColor(.secondary)
					if match.performanceBonus != 0 {
						Text("Bonus: +\(match.performanceBonus)")
							.foregroundColor(.green)
					}
					if match.afkPenalty != 0 {
						Text("AFK Penalty: \(match.afkPenalty)")
							.foregroundColor(.red)
					}
				}
				
				Spacer()
				
				if match.isRanked {
					VStack(alignment: .trailing) {
						let eloChange = match.eloChange
						Text(eloChange > 0 ? "+\(eloChange)" : eloChange < 0 ? "\(eloChange)" : "=")
							.foregroundColor(changeColor)
						Text("\(match.tierProgressAfterUpdate)")
							.foregroundColor(.gray)
					}
					
					changeRing
				}
			}
		}
		.padding(.vertical, 4)
		.id(match.id)
	}
	
	private var mapIcon: some View {
		MapImage.splash(match.mapID)
			.aspectRatio(16/9, contentMode: .fill)
			.frame(height: visualsHeight)
			.fixedSize()
			.overlay(MapImage.Label(mapID: match.mapID))
			.mask(RoundedRectangle(cornerRadius: 6, style: .continuous))
	}
	
	private var changeColor: Color {
		match.eloChange > 0 ? .green : match.eloChange < 0 ? .red : .gray
	}
	
	@ViewBuilder
	private var changeRing: some View {
		let lineWidth: CGFloat = 4
		
		ZStack {
			let before = CGFloat(match.eloBeforeUpdate) / 100
			let after = CGFloat(match.eloAfterUpdate) / 100
			
			let ring = Circle().rotation(Angle(degrees: -90))
			let stroke = StrokeStyle(lineWidth: lineWidth, lineCap: .round)
			
			ring
				.stroke(Color.gray.opacity(0.2), style: stroke)
			
			ZStack {
				ring
					.trim(from: 0, to: after.truncatingRemainder(dividingBy: 1))
					.stroke(Color.gray, style: stroke)
				
				let changeRing = ring
					.trim(from: 0, to: abs(after - before))
					.rotation(Angle(degrees: Double(360 * min(before, after))))
				
				changeRing
					.stroke(Color.black, style: stroke <- { $0.lineWidth += 2 })
					.blendMode(.destinationOut)
				
				changeRing
					.stroke(changeColor, style: stroke)
				
				CompetitiveTierImage(tier: match.tierAfterUpdate)
					.padding(10)
			}
			.compositingGroup()
			
			movementIndicator
				.background(Circle().fill(Color.white).blendMode(.destinationOut))
				.alignmentGuide(.top) { $0[VerticalAlignment.center] }
				.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
		}
		.compositingGroup()
		.padding(lineWidth / 2)
		.aspectRatio(contentMode: .fit)
		.frame(height: visualsHeight)
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
	static let promotion = CompetitiveUpdate.example(tierChange: (21, 22), tierProgressChange: (80, 10), index: 0)
	static let increase = CompetitiveUpdate.example(tierChange: (8, 8), tierProgressChange: (40, 60), index: 1)
	static let unchanged = CompetitiveUpdate.example(tierChange: (12, 12), tierProgressChange: (50, 50), index: 2)
	static let decrease = CompetitiveUpdate.example(tierChange: (8, 8), tierProgressChange: (60, 40), index: 3)
	static let demotion = CompetitiveUpdate.example(tierChange: (6, 5), tierProgressChange: (10, 80), index: 4)
	
	static let jump = CompetitiveUpdate.example(tierChange: (11, 13), tierProgressChange: (90, 30))
	
	static let unranked = CompetitiveUpdate.example(tierChange: (0, 0), tierProgressChange: (0, 0))
	
	static let allExamples = [unranked, promotion, increase, unchanged, decrease, demotion, jump]
	
	static var previews: some View {
		VStack(spacing: 0) {
			Divider()
			ForEach(allExamples) {
				MatchCell(match: $0, userID: PreviewData.userID)
					.padding()
				Divider()
			}
		}
		.inEachColorScheme()
		.previewLayout(.sizeThatFits)
	}
}
#endif
