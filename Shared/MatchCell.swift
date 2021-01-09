import SwiftUI
import SwiftUIMissingPieces
import HandyOperators

struct MatchCell: View {
	static let dateFormatter = DateFormatter() <- {
		$0.dateStyle = .short
	}
	static let timeFormatter = DateFormatter() <- {
		$0.timeStyle = .short
	}
	
	let match: Match
	
	var body: some View {
		HStack {
			Image("map_\(match.mapName.lowercased())")
				.resizable()
				.aspectRatio(contentMode: .fit)
				.overlay(
					Text(match.mapName)
						.font(Font.callout.smallCaps())
						.bold()
						.foregroundColor(.white)
						.shadow(radius: 1)
						.padding(.leading, 4) // visual alignment
						.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
						.blendMode(.overlay)
				)
				.mask(RoundedRectangle(cornerRadius: 4, style: .continuous))
			
			VStack(alignment: .leading) {
				Text(Self.dateFormatter.string(from: match.startTime))
				Text(Self.timeFormatter.string(from: match.startTime))
					.foregroundColor(.secondary)
			}
			
			Spacer()
			
			let eloChange = match.eloAfterUpdate - match.eloBeforeUpdate
			let changeColor: Color = eloChange > 0 ? .green : eloChange < 0 ? .red : .gray
			
			VStack(alignment: .trailing) {
				Text(eloChange > 0 ? "+\(eloChange)" : eloChange < 0 ? "\(eloChange)" : "=")
					.foregroundColor(changeColor)
				Text("\(match.tierProgressAfterUpdate)")
					.foregroundColor(.gray)
			}
			
			let lineWidth: CGFloat = 4
			
			ZStack {
				let before = CGFloat(match.eloBeforeUpdate) / 100
				let after = CGFloat(match.eloAfterUpdate) / 100
				
				let ring = Circle().rotation(Angle(degrees: -90))
				let stroke = StrokeStyle(lineWidth: lineWidth, lineCap: .round)
				
				ring
					.stroke(Color.gray.opacity(0.2), style: stroke)
				
				let changeRing = ring
					.trim(from: 0, to: abs(after - before))
					.rotation(Angle(degrees: Double(360 * min(before, after))))
				
				let invertedChangeRing = ZStack {
					Rectangle()
						.fill(Color.white)
						.padding(-lineWidth - 1)
					changeRing
						.stroke(Color.black, style: stroke <- { $0.lineWidth += 2 })
				}
				.compositingGroup()
				.luminanceToAlpha()
				
				ring
					.trim(from: 0, to: after.truncatingRemainder(dividingBy: 1))
					.stroke(Color.gray, style: stroke)
					.mask(invertedChangeRing)
				
				changeRing
					.stroke(changeColor, style: stroke)
				
				Image("tier_\(match.tierAfterUpdate)")
					.resizable()
					.padding(10)
			}
			.padding(lineWidth / 2)
			.aspectRatio(contentMode: .fit)
		}
		.frame(height: 64)
	}
}

struct MatchCell_Previews: PreviewProvider {
	static let promotion = Match.example(tierChange: (5, 6), tierProgressChange: (80, 10), mapIndex: 0)
	static let increase = Match.example(tierChange: (8, 8), tierProgressChange: (40, 60), mapIndex: 1)
	static let unchanged = Match.example(tierChange: (12, 12), tierProgressChange: (50, 50), mapIndex: 2)
	static let decrease = Match.example(tierChange: (8, 8), tierProgressChange: (60, 40), mapIndex: 3)
	static let demotion = Match.example(tierChange: (6, 5), tierProgressChange: (10, 80), mapIndex: 4)
	
	static let jump = Match.example(tierChange: (11, 13), tierProgressChange: (90, 30))
	
	static let allExamples = [promotion, increase, unchanged, decrease, demotion, jump]
	
	static var previews: some View {
		ForEach(ColorScheme.allCases, id: \.hashValue) {
			VStack(spacing: 0) {
				Divider()
				ForEach(allExamples) {
					MatchCell(match: $0)
						.padding()
					Divider()
				}
			}
			.preferredColorScheme($0)
		}
	}
}

let tiers: [String] = ["INVALID", "iron", "silver", "gold", "platinum", "diamond", "immortal"]
	.flatMap { rank in (1...3).map { "\(rank) \($0)" } }
	+ ["radiant"]
