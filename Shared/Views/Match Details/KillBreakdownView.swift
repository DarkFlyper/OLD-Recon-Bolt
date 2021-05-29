import SwiftUI
import ValorantAPI
import HandyOperators

struct KillBreakdownView: View {
	let data: MatchViewData
	@Binding var highlight: PlayerHighlightInfo
	
	static func canDisplay(for data: MatchViewData) -> Bool {
		data.details.teams.count == 2
			&& data.details.roundResults.count > 1
	}
	
	// I tried to do this with alignment guides but this solution ended up being cleaner
	@State private var topHeight: CGFloat = 0
	@State private var bottomHeight: CGFloat = 0
	
	var body: some View {
		let rounds = collectRoundData()
		ScrollView(.horizontal, showsIndicators: false) {
			HStack(spacing: 1) {
				ForEach(rounds, content: roundBreakdown)
			}
			.fixedSize()
			.padding(.horizontal)
		}
		.onPreferenceChange(TopHeight.self) { topHeight = $0 }
		.onPreferenceChange(BottomHeight.self) { bottomHeight = $0 }
	}
	
	private func collectRoundData() -> [Round] {
		assert(Self.canDisplay(for: data))
		
		// order players by number of kills, with self in first place
		let killsByPlayer = Dictionary(
			grouping: data.details.nonBombKills(),
			by: \.killer
		)
		let order = killsByPlayer
			.sorted { data.players[$0.key]!.stats.score }
				then: { $0.key.rawValue.uuidString }
			.map(\.key)
			.reversed()
			.movingToFront { $0 == data.myself?.id }
		let playerOrder = Dictionary(uniqueKeysWithValues: order.enumerated().map { ($0.element, $0.offset) })
		
		let orderedTeams = data.details.teams
			.movingToFront { $0.id == data.myself?.teamID }
		
		return zip(
			data.details.roundResults,
			data.details.killsByRound()
		).map { result, kills in
			Round(
				result: result,
				kills: kills,
				killsByTeam: orderedTeams.map { team in
					kills
						.filter { data.players[$0.killer]!.teamID == team.id }
						.sorted { playerOrder[$0.killer]! }
				}
			)
		}
	}
	
	private func roundBreakdown(for round: Round) -> some View {
		VStack(spacing: 1) {
			let backgroundOpacity = 0.25
			let relativeColor = data.relativeColor(of: round.result.winningTeam)
			
			killIcons(for: round.killsByTeam[0].reversed())
				.measuring(\.height, as: TopHeight.self)
				.frame(height: topHeight, alignment: .bottom)
				.background(
					LinearGradient(
						gradient: .init(.valorantBlue),
						startPoint: .bottom, endPoint: .top
					)
					.opacity(backgroundOpacity)
				)
			
			Text("\(round.result.number + 1)")
				.bold()
				.foregroundColor(relativeColor)
				.padding(.vertical, 8)
				.frame(maxWidth: .infinity)
				.background(relativeColor?.opacity(backgroundOpacity))
			
			killIcons(for: round.killsByTeam[1])
				.measuring(\.height, as: BottomHeight.self)
				.frame(height: bottomHeight, alignment: .top)
				.background(
					LinearGradient(
						gradient: .init(.valorantRed),
						startPoint: .top, endPoint: .bottom
					)
					.opacity(backgroundOpacity)
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
		let player = data.players[playerID]!
		let relativeColor = data.relativeColor(of: player) ?? .valorantRed
		
		AgentImage.displayIcon(player.agentID)
			.frame(width: 32, height: 32)
			.dynamicallyStroked(radius: 1, color: .white)
			.background(Circle().fill(relativeColor).opacity(0.5).padding(1))
			.mask(Circle())
			.padding(1)
			.overlay(Circle().strokeBorder(relativeColor))
			.background(
				Circle()
					.strokeBorder(lineWidth: 3)
					.opacity(0.5)
					.blendMode(.destinationOut)
					.padding(-1)
			)
			.compositingGroup()
			.opacity(highlight.shouldFade(playerID) ? 0.5 : 1)
			.onTapGesture {
				highlight.switchHighlight(to: player)
			}
	}
}

private typealias TopHeight = MaxHeightPreference<TopMarker>
private enum TopMarker {}

private typealias BottomHeight = MaxHeightPreference<BottomMarker>
private enum BottomMarker {}

private struct MaxHeightPreference<Marker>: PreferenceKey {
	static var defaultValue: CGFloat { -.infinity }
	static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
		value = max(value, nextValue())
	}
}

#if DEBUG
struct KillBreakdownView_Previews: PreviewProvider {
	static var previews: some View {
		// computing these previews takes a long time, so we'll limit ourselves to one match
		KillBreakdownView(data: PreviewData.singleMatchData, highlight: .constant(.init()))
			.padding(.vertical)
			.inEachColorScheme()
			.environmentObject(AssetManager.forPreviews)
			.frame(maxWidth: 800, minHeight: 600)
			.previewLayout(.sizeThatFits)
	}
}
#endif

private struct Round: Identifiable {
	var id: Int { result.number }
	
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
