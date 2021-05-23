import SwiftUI
import SwiftUIMissingPieces
import ValorantAPI
import HandyOperators
import ArrayBuilder

struct KillBreakdownView: View {
	let players: [Player.ID: Player]
	let myself: Player?
	private let rounds: [Round]
	
	static func canDisplay(for matchDetails: MatchDetails) -> Bool {
		matchDetails.teams.count == 2
	}
	
	init(matchDetails: MatchDetails, myself: Player?) {
		assert(matchDetails.teams.count == 2)
		
		self.myself = myself
		self.players = .init(uniqueKeysWithValues: matchDetails.players.map { ($0.id, $0) })
		
		// order players by number of kills, with self in first place
		let killsByPlayer = Dictionary(
			grouping: matchDetails.nonBombKills(),
			by: \.killer
		)
		let order = killsByPlayer
			.sorted(on: \.value.count)
			.map(\.key)
			.reversed()
			.movingToFront { $0 == myself?.id }
		let playerOrder = Dictionary(uniqueKeysWithValues: order.enumerated().map { ($0.element, $0.offset) })
		
		let orderedTeams = matchDetails.teams
			.movingToFront { $0.id == myself?.teamID }
		
		self.rounds = zip(
			matchDetails.roundResults,
			matchDetails.killsByRound()
		).map { [players] result, kills in
			Round(
				result: result,
				kills: kills,
				killsByTeam: orderedTeams.map { team in
					kills
						.filter { players[$0.killer]!.teamID == team.id }
						.sorted { playerOrder[$0.killer]! }
				}
			)
		}
	}
	
	// I tried to do this with alignment guides but this solution ended up being cleaner
	@State private var topHeight: CGFloat = 0
	@State private var bottomHeight: CGFloat = 0
	
	var body: some View {
		ScrollView(.horizontal) {
			HStack(spacing: 1) {
				ForEach(rounds, content: roundBreakdown)
			}
			.fixedSize()
			.padding(.horizontal)
		}
		.onPreferenceChange(TopHeight.self) { topHeight = $0 }
		.onPreferenceChange(BottomHeight.self) { bottomHeight = $0 }
	}
	
	private func roundBreakdown(for round: Round) -> some View {
		VStack(spacing: 1) {
			let backgroundOpacity = 0.5
			
			killIcons(for: round.killsByTeam[0].reversed())
				.measuring(\.height, as: TopHeight.self)
				.frame(height: topHeight, alignment: .bottom)
				.background(
					LinearGradient(
						gradient: .init(.valorantBlue),
						startPoint: .bottom, endPoint: .top
					).opacity(backgroundOpacity)
				)
			
			Text("\(round.result.number + 1)")
				.bold()
				.blendMode(.destinationOut)
				.padding(.vertical, 8)
				.frame(maxWidth: .infinity)
				.background(color(for: round.result.winningTeam)?.opacity(backgroundOpacity))
			
			killIcons(for: round.killsByTeam[1])
				.measuring(\.height, as: BottomHeight.self)
				.frame(height: bottomHeight, alignment: .top)
				.background(
					LinearGradient(
						gradient: .init(.valorantRed),
						startPoint: .top, endPoint: .bottom
					).opacity(backgroundOpacity)
				)
		}
		.fixedSize()
	}
	
	@ViewBuilder
	private func killIcons(for kills: [Kill]) -> some View {
		VStack(spacing: 8) {
			ForEach(Array(kills.enumerated()), id: \.offset) { _, kill in
				playerIcon(for: kill.killer)
			}
		}
		.padding(8)
		.fixedSize()
		.frame(maxWidth: .infinity)
	}
	
	@ViewBuilder
	private func playerIcon(for playerID: Player.ID) -> some View {
		let player = players[playerID]!
		let teamColor = color(for: player.teamID) ?? .valorantBlue
		let teamOrSelfColor = player.id == myself?.id ? .valorantSelf : teamColor
		let borderWidth: CGFloat = 1
		
		AgentImage.displayIcon(player.agentID)
			.frame(width: 32, height: 32)
			.dynamicallyStroked(radius: 1, color: .white)
			.padding(borderWidth)
			.background(teamOrSelfColor.opacity(0.5))
			.mask(Circle())
			.overlay(Circle().strokeBorder(teamOrSelfColor, lineWidth: borderWidth))
	}
	
	private func color(for teamID: Team.ID) -> Color? {
		if let own = myself?.teamID {
			return teamID == own ? .valorantBlue : .valorantRed
		} else {
			return teamID.color
		}
	}
	
	private func maximalRound() -> Round {
		let maximalKills = rounds
			.map(\.killsByTeam)
			.transposed()
			.map { $0.max { $0.count < $1.count }! }
		return Round(
			result: rounds.first!.result,
			kills: maximalKills.flatMap { $0 },
			killsByTeam: maximalKills
		)
	}
}

private extension Gradient {
	init(_ color: Color, opacities: [Double] = [1, 0]) {
		self.init(colors: opacities.map(color.opacity))
	}
}

private extension View {
	func measuring<Key: PreferenceKey>(
		_ path: KeyPath<CGSize, CGFloat>, as key: Key.Type
	) -> some View where Key.Value == CGFloat {
		modifier(Measuring<Key>(measurePath: path))
	}
}

private struct Measuring<Key: PreferenceKey>: ViewModifier where Key.Value == CGFloat {
	let measurePath: KeyPath<CGSize, CGFloat>
	
	@State private var value: CGFloat = 0
	
	func body(content: Content) -> some View {
		content
			.measured { value = $0[keyPath: measurePath] }
			.preference(key: Key.self, value: value)
	}
}

private typealias TopHeight = MaxHeightPreference<TopMarker>
private typealias BottomHeight = MaxHeightPreference<BottomMarker>
private enum TopMarker {}
private enum BottomMarker {}
private struct MaxHeightPreference<Marker>: PreferenceKey {
	static var defaultValue: CGFloat { -.infinity }
	static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
		value = max(value, nextValue())
	}
}

struct KillBreakdownView_Previews: PreviewProvider {
	static var previews: some View {
		// computing these previews takes a long time, so we'll limit ourselves to one match
		let match = PreviewData.singleMatch
		
		KillBreakdownView(
			matchDetails: match,
			myself: match.players.first { $0.id == PreviewData.playerID }
		)
		.padding(.vertical)
		.inEachColorScheme()
		.environmentObject(AssetManager.forPreviews)
		//.fixedSize(horizontal: true, vertical: true)
		.frame(maxWidth: 800)
		.previewLayout(.sizeThatFits)
	}
}

private struct Round: Identifiable {
	let id = UUID()
	
	let result: RoundResult
	let kills: [Kill]
	let killsByTeam: [[Kill]]
}

private extension MatchDetails {
	func nonBombKills() -> [Kill] {
		kills.filter { $0.finishingDamage.type != .bomb }
	}
	
	func killsByRound() -> [[Kill]] {
		Array(
			repeating: [] as [Kill],
			count: roundResults.count
		) <- {
			for kill in nonBombKills() {
				$0[kill.round!].append(kill)
			}
		}
	}
}
