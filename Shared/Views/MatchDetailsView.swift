import SwiftUI
import SwiftUIMissingPieces
import ValorantAPI
import VisualEffects
import HandyOperators

struct MatchDetailsContainer: View {
	@EnvironmentObject private var loadManager: LoadManager
	@Environment(\.playerID) private var playerID
	
	let matchID: Match.ID
	
	@State var matchDetails: MatchDetails?
	
	var body: some View {
		Group {
			if let details = matchDetails {
				MatchDetailsView(matchDetails: details, playerID: playerID)
			} else {
				ProgressView()
			}
		}
		.loadErrorTitle("Could not load match details!")
		.onAppear {
			if matchDetails == nil {
				loadManager.load {
					$0.getMatchDetails(matchID: matchID)
				} onSuccess: { matchDetails = $0 }
			}
		}
		.navigationBarTitleDisplayMode(.inline)
		.navigationTitle("Match Details")
	}
}

private extension CoordinateSpace {
	static let scrollView = Self.named("scrollView")
}

struct MatchDetailsView: View {
	let matchDetails: MatchDetails
	let myself: Player?
	
	init(matchDetails: MatchDetails, playerID: Player.ID?) {
		self.matchDetails = matchDetails
		
		let candidates = matchDetails.players.filter { $0.id == playerID }
		assert(candidates.count <= 1)
		myself = candidates.first
	}
	
	var body: some View {
		ScrollView {
			VStack(spacing: 0) {
				hero
					.edgesIgnoringSafeArea(.horizontal)
				
				scoreboard
			}
		}
		.coordinateSpace(name: CoordinateSpace.scrollView)
	}
	
	@ViewBuilder
	private var scoreboard: some View {
		let columns = [
			GridItem(.flexible(), spacing: 1),
			GridItem(.fixed(80), spacing: 1),
			GridItem(.fixed(140), spacing: 1),
		]
		let sorted = matchDetails.players.sorted { $0.stats.score > $1.stats.score }
		LazyVGrid(columns: columns, spacing: 1) {
			ForEach(sorted) { player in
				scoreboardRow(for: player)
			}
		}
		.colorScheme(.dark)
		.padding(1)
	}
	
	@ViewBuilder
	private func scoreboardRow(for player: Player) -> some View {
		Group {
			Text(verbatim: player.gameName)
				.fontWeight(.medium)
				.padding(6)
				.frame(maxWidth: .infinity, alignment: .leading)
			
			Text(verbatim: "\(player.stats.score)")
				.padding(6)
			
			HStack {
				Text(verbatim: "\(player.stats.kills)")
				Text("/").opacity(0.5)
				Text(verbatim: "\(player.stats.deaths)")
				Text("/").opacity(0.5)
				Text(verbatim: "\(player.stats.assists)")
			}
			.padding(6)
		}
		.frame(maxWidth: .infinity)
		.background(color(for: player.teamID))
	}
	
	func color(for teamID: Team.ID) -> Color? {
		if let own = myself?.teamID {
			return teamID == own ? .valorantBlue : .valorantRed
		} else {
			return teamID.color
		}
	}
	
	private var hero: some View {
		ZStack {
			matchDetails.matchInfo.mapID.mapImage
				.aspectRatio(contentMode: .fill)
				.frame(height: 150)
				.clipped()
				.overlay(mapLabel)
			
			scoreSummary(for: matchDetails.teams)
				.font(.largeTitle.weight(.heavy))
				.padding(.horizontal, 6)
				.background(
					VisualEffectBlur(blurStyle: .systemThinMaterialDark)
						.roundedAndStroked(cornerRadius: 8)
				)
				.shadow(radius: 10)
				.colorScheme(.dark)
		}
	}
	
	private var mapLabel: some View {
		Text(matchDetails.matchInfo.mapID.mapName ?? "unknown")
			.font(Font.callout.smallCaps())
			.bold()
			.foregroundColor(.white)
			.shadow(radius: 1)
			.padding(.bottom, -2) // visual alignment
			.padding()
			.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
			.blendMode(.overlay)
	}
	
	
	@ViewBuilder
	private func scoreSummary(for teams: [Team]) -> some View {
		let _ = assert(!teams.isEmpty)
		let sorted = teams.sorted {
			$0.id == myself?.teamID // self first
				|| $1.id != myself?.teamID // self first
				&& $0.pointCount > $1.pointCount // sort decreasingly by score
		}
		
		if sorted.count >= 2 {
			HStack {
				Text(verbatim: "\(sorted[0].pointCount)")
					.foregroundColor(.valorantBlue)
				Text("–")
					.opacity(0.5)
				Text(verbatim: "\(sorted[1].pointCount)")
					.foregroundColor(.valorantRed)
				
				if sorted.count > 2 {
					Text("–")
						.opacity(0.5)
					Text(verbatim: "…")
						.foregroundColor(.valorantRed)
				}
			}
		} else {
			Text(verbatim: "\(sorted[0].pointCount) points")
		}
	}
	
	private func scoreText(for team: Team) -> some View {
		Text(verbatim: "\(team.pointCount)")
			.foregroundColor(team.id.color)
	}
}

struct MatchDetailsView_Previews: PreviewProvider {
	static let exampleMatchData = try! Data(
		contentsOf: Bundle.main
			.url(forResource: "example_match", withExtension: "json")!
	)
	static let exampleMatch = try! Client.responseDecoder
		.decode(MatchDetails.self, from: exampleMatchData)
	static let playerID = Player.ID(.init(uuidString: "3FA8598D-066E-5BDB-998C-74C015C5DBA5")!)
	
	static var previews: some View {
		ForEach(ColorScheme.allCases, id: \.self) { scheme in
			NavigationView {
				MatchDetailsView(matchDetails: exampleMatch, playerID: playerID)
					.navigationBarTitleDisplayMode(.inline)
					.navigationTitle("Match Details")
			}
			.navigationViewStyle(StackNavigationViewStyle())
			.preferredColorScheme(scheme)
		}
	}
}

extension EnvironmentValues {
	private enum PlayerIDKey: EnvironmentKey {
		static let defaultValue: Player.ID? = nil
	}
	
	var playerID: Player.ID? {
		get { self[PlayerIDKey.self] }
		set { self[PlayerIDKey.self] = newValue }
	}
}
