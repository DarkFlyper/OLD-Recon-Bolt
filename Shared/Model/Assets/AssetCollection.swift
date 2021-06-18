import Foundation
import ArrayBuilder
import ValorantAPI

struct AssetCollection: Codable {
	let version: AssetVersion
	
	let maps: [MapID: MapInfo]
	let agents: [Agent.ID: AgentInfo]
	let missions: [Mission.ID: MissionInfo]
	let objectives: [Objective.ID: ObjectiveInfo]
	let playerCards: [PlayerCard.ID: PlayerCardInfo]
	let playerTitles: [PlayerTitle.ID: PlayerTitleInfo]
	let competitiveTierEpisodes: [CompetitiveTier.Episode]
	
	var images: Set<AssetImage> {
		Set()
			.union(maps.values.flatMap(\.images))
			.union(agents.values.flatMap(\.images))
			.union(playerCards.values.flatMap(\.images))
			.union(competitiveTierEpisodes.flatMap(\.images))
	}
}

protocol AssetItem {
	@ArrayBuilder<AssetImage>
	var images: [AssetImage] { get }
}

extension AssetItem {
	var images: [AssetImage] { [] }
}
