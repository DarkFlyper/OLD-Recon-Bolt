import SwiftUI
import ValorantAPI
import HandyOperators

struct KillBreakdownView: View {
	let data: MatchViewData
	@Binding var highlight: PlayerHighlightInfo
	@AppStorage("KillBreakdownView.isCompact")
	private var isCompact = false
	
	static func canDisplay(for data: MatchViewData) -> Bool {
		data.details.teams.count == 2
			&& data.details.roundResults.count > 1
	}
	
	// I tried to do this with alignment guides but this solution ended up being cleaner
	@State private var topHeight: CGFloat = 0
	@State private var bottomHeight: CGFloat = 0
	
	var body: some View {
		let rounds = collectRoundData()
		VStack {
			HStack {
				Text("Kills by Round")
					.font(.headline)
				
				Spacer()
				
				Button { isCompact.toggle() } label: {
					Image(
						systemName: isCompact
							? "arrowtriangle.left.fill.and.line.vertical.and.arrowtriangle.right.fill"
							: "arrowtriangle.right.fill.and.line.vertical.and.arrowtriangle.left.fill"
					)
				}
			}
			.padding(.horizontal)
			
			ScrollView(.horizontal, showsIndicators: false) {
				HStack(spacing: 1) {
					ForEach(rounds) { roundBreakdown(for: $0) }
				}
				.padding(.horizontal)
			}
			.onPreferenceChange(TopHeight.self) { topHeight = $0 }
			.onPreferenceChange(BottomHeight.self) { bottomHeight = $0 }
		}
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
	
	private var spacing: CGFloat { isCompact ? 3 : 8 }
	
	@ScaledMetric private var roundNumberSize = 20
	
	@ViewBuilder
	private func roundBreakdown(for round: Round) -> some View {
		let width: CGFloat = isCompact ? 30 : 50
		
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
				.font(.system(size: roundNumberSize * (isCompact ? 0.6 : 1)))
				.bold()
				.foregroundColor(relativeColor)
				.padding(.vertical, spacing)
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
		.frame(width: width)
		.opacity(round.result.outcome == .surrendered ? 0.5 : 1)
	}
	
	@ViewBuilder
	private func killIcons(for kills: [Kill]) -> some View {
		VStack(spacing: spacing) {
			ForEach(Array(kills.enumerated()), id: \.offset) { _, kill in
				playerIcon(for: kill.killer)
			}
		}
		.padding(spacing)
		.frame(maxWidth: .infinity)
	}
	
	@ViewBuilder
	private func playerIcon(for playerID: Player.ID) -> some View {
		let player = data.players[playerID]!
		let relativeColor = data.relativeColor(of: player) ?? .valorantRed
		
		AgentImage.displayIcon(player.agentID)
			.fixedSize(horizontal: false, vertical: true)
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
	static var defaultValue: CGFloat { 0 }
	static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
		value = max(value, nextValue())
	}
}

#if DEBUG
struct KillBreakdownView_Previews: PreviewProvider {
	static var previews: some View {
		// computing these previews takes a long time, so we'll limit ourselves to one match
		KillBreakdownView(data: PreviewData.singleMatchData, highlight: .constant(.init()))
			.previewInterfaceOrientation(.landscapeRight)
			//.padding(.vertical)
			//.inEachColorScheme()
			.withPreviewAssets()
			//.frame(maxWidth: 800, minHeight: 600)
			//.previewLayout(.sizeThatFits)
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
