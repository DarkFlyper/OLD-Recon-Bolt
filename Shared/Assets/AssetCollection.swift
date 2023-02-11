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
	let sprays: [Spray.ID: SprayInfo]
	let buddies: [Weapon.Buddy.ID: BuddyInfo]
	let currencies: [Currency.ID: CurrencyInfo]
	let bundles: [StoreBundle.Asset.ID: StoreBundleInfo]
}

/// just a marker at this point, but still handy for expressivity
protocol AssetItem {}
