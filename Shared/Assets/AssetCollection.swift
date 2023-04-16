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
	let queues: [QueueID: QueueInfo]
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
	let contentTiers: [ContentTier.ID: ContentTier]
}

enum AssetLanguage: String, Codable {
	case arabic = "ar-AE"
	case german = "de-DE"
	case english = "en-US"
	case spanishEU = "es-ES"
	case spanishSA = "es-MX"
	case french = "fr-FR"
	case indonesian = "id-ID"
	case italian = "it-IT"
	case japanese = "ja-JP"
	case korean = "ko-KR"
	case polish = "pl-PL"
	case portuguese = "pt-BR"
	case russian = "ru-RU"
	case thai = "th-TH"
	case turkish = "tr-TR"
	case vietnamese = "vi-VN"
	case chineseSimplified = "zh-CN"
	case chineseTraditional = "zh-TW"
}

/// just a marker at this point, but still handy for expressivity
protocol AssetItem {}
