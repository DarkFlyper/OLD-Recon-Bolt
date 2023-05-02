import Foundation
import ArrayBuilder
import ValorantAPI

struct AssetCollection: Codable {
	let version: AssetVersion
	let language: String
	
	let maps: [MapID: MapInfo]
	let agents: [Agent.ID: AgentInfo]
	let missions: [Mission.ID: MissionInfo]
	let contracts: [Contract.ID: ContractInfo]
	let gameModes: [GameMode.ID: GameModeInfo]
	let queues: [QueueID: QueueInfo]
	let objectives: [Objective.ID: ObjectiveInfo]
	let playerCards: [PlayerCard.ID: PlayerCardInfo]
	let playerTitles: [PlayerTitle.ID: PlayerTitleInfo]
	let weapons: [Weapon.ID: WeaponInfo]
	let seasons: SeasonCollection
	let skinsByLevelID: [WeaponSkin.Level.ID: WeaponSkin.Level.Path]
	let sprays: [Spray.ID: SprayInfo]
	let buddies: [Weapon.Buddy.ID: BuddyInfo]
	let buddiesByLevelID: [Weapon.Buddy.Level.ID: Weapon.Buddy.ID]
	let currencies: [Currency.ID: CurrencyInfo]
	let bundles: [StoreBundle.Asset.ID: StoreBundleInfo]
	let contentTiers: [ContentTier.ID: ContentTier]
}

/// just a marker at this point, but still handy for expressivity
protocol AssetItem {}

extension Locale {
	static let valorantLanguages: [String] = [
		"ar-AE", // arabic
		"de-DE", // german
		"en-US", // english
		"es-ES", // spanish (european)
		"es-MX", // spanish (latin american)
		"fr-FR", // french
		"id-ID", // indonesian
		"it-IT", // italian
		"ja-JP", // japanese
		"ko-KR", // korean
		"pl-PL", // polish
		"pt-BR", // portuguese (brasilian)
		"ru-RU", // russian
		"th-TH", // thai
		"tr-TR", // turkish
		"vi-VN", // vietnamese
		"zh-CN", // chinese (simplified)
		"zh-TW", // chinese (traditional)
	]
}
