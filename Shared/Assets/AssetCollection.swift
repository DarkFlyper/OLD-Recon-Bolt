import Foundation
import ArrayBuilder
import ValorantAPI

struct AssetCollection: Codable {
	let version: AssetVersion
	
	let maps: [MapID: MapInfo]
	let agents: [Agent.ID: AgentInfo]
	let missions: [Mission.ID: MissionInfo]
	let contracts: [Contract.ID: ContractInfo]
	let gameModes: [GameMode.ID: GameModeInfo]
	let objectives: [Objective.ID: ObjectiveInfo]
	let playerCards: [PlayerCard.ID: PlayerCardInfo]
	let playerTitles: [PlayerTitle.ID: PlayerTitleInfo]
	let weapons: [Weapon.ID: WeaponInfo]
	let seasons: SeasonCollection
	let skinsByLevelID: [WeaponSkin.Level.ID: WeaponSkin.Level.Path]
	let currencies: [Currency.ID: CurrencyInfo]
	let bundles: [StoreBundle.Asset.ID: StoreBundleInfo]
	
	var images: Set<AssetImage> {
		Set<AssetImage>()
			.union(maps.values.flatMap(\.images))
			.union(agents.values.flatMap(\.images))
			.union(contracts.values.flatMap(\.images))
			.union(gameModes.values.flatMap(\.images))
			.union(playerCards.values.flatMap(\.images))
			.union(weapons.values.flatMap(\.images))
			.union(seasons.images)
			.union(currencies.values.flatMap(\.images))
	}
}

protocol AssetItem {
	@ArrayBuilder<AssetImage>
	var images: [AssetImage] { get }
}

extension AssetItem {
	var images: [AssetImage] { [] }
}
