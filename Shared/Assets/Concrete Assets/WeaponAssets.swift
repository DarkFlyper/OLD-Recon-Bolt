import Foundation
import ValorantAPI
import HandyOperators

extension AssetClient {
	func getWeaponInfo() async throws -> [WeaponInfo] {
		try await send(WeaponInfoRequest())
	}
}

private struct WeaponInfoRequest: AssetDataRequest {
	let path = "/v1/weapons"
	
	typealias Response = [WeaponInfo]
}

struct WeaponInfo: AssetItem, Codable, Identifiable {
	var id: Weapon.ID
	var displayName: String
	var category: Category
	var defaultSkinID: WeaponSkin.ID
	var displayIcon: AssetImage
	var killStreamIcon: AssetImage
	var stats: WeaponStats?
	var shopData: ShopData?
	// this also has info on skins but I don't care about those for now.
	var skins: [WeaponSkin]
	
	var images: [AssetImage] {
		displayIcon
		killStreamIcon
		shopData?.image
	}
	
	private enum CodingKeys: String, CodingKey {
		case id = "uuid"
		case displayName
		case category
		case defaultSkinID = "defaultSkinUuid"
		case displayIcon
		case killStreamIcon
		case stats = "weaponStats"
		case shopData
		case skins
	}
	
	struct Category: NamespacedID {
		static let melee = Self("Melee")
		static let sidearm = Self("Sidearm")
		static let smg = Self("Smg")
		static let shotgun = Self("Shotgun")
		static let rifle = Self("Rifle")
		static let heavy = Self("Heavy")
		static let sniper = Self("Sniper")
		
		static let namespace = "EEquippableCategory"
		var rawValue: String
	}
	
	struct ShopData: Codable {
		var price: Int
		var category: String
		var canBeTrashed: Bool // this always seems to be true
		var image: AssetImage
		
		private enum CodingKeys: String, CodingKey {
			case price = "cost"
			case category = "categoryText"
			case canBeTrashed
			case image = "newImage"
		}
	}
}

struct WeaponSkin: AssetItem, Codable, Identifiable {
	var id: Weapon.Skin.ID
	var displayName: String
	var themeID: Theme.ID
	var contentTierID: ContentTier.ID?
	var displayIcon: AssetImage?
	var wallpaper: AssetImage?
	var chromas: [Chroma]
	var levels: [Level]
	
	private enum CodingKeys: String, CodingKey {
		case id = "uuid"
		case displayName
		case themeID = "themeUuid"
		case contentTierID = "contentTierUuid"
		case displayIcon
		case wallpaper
		case chromas
		case levels
	}
	
	enum Theme {
		typealias ID = ObjectID<Self, LowercaseUUID>
	}
	
	enum ContentTier {
		typealias ID = ObjectID<Self, LowercaseUUID>
	}
	
	struct Chroma: AssetItem, Codable, Identifiable {
		var id: Weapon.Skin.Chroma.ID
		var displayName: String
		var displayIcon: AssetImage?
		var fullRender: AssetImage
		var swatch: AssetImage?
		var streamedVideo: URL?
		
		private enum CodingKeys: String, CodingKey {
			case id = "uuid"
			case displayName
			case displayIcon
			case fullRender
			case swatch
			case streamedVideo
		}
	}
	
	struct Level: AssetItem, Codable, Identifiable {
		var id: Weapon.Skin.Level.ID
		var displayName: String?
		var levelItem: Item?
		var displayIcon: AssetImage?
		var streamedVideo: URL?
		
		private enum CodingKeys: String, CodingKey {
			case id = "uuid"
			case displayName
			case levelItem
			case displayIcon
			case streamedVideo
		}
		
		struct Item: NamespacedID {
			static let animation = Self("Animation")
			static let finisher = Self("Finisher")
			static let inspectAndKill = Self("InspectAndKill")
			static let killCounter = Self("KillCounter")
			static let killBanner = Self("KillBanner")
			static let randomizer = Self("Randomizer")
			static let topFrag = Self("TopFrag")
			static let vfx = Self("VFX")
			static let voiceover = Self("Voiceover")
			
			static let namespace = "EEquippableSkinLevelItem"
			var rawValue: String
			
			private static let descriptionOverrides: [Self: String] = [
				.killCounter: "Kill Counter",
				.killBanner: "Kill Banner",
				.topFrag: "Champion's Aura",
				.inspectAndKill: "Inspect & Kill Effects",
			]
			
			var description: String {
				Self.descriptionOverrides[self] ?? rawValue
			}
		}
		
		struct Path: Hashable, Codable {
			var weapon: Weapon.ID
			var skinIndex: Int
			var levelIndex: Int
		}
	}
}

extension WeaponSkin.Theme.ID {
	static let standard = Self("5a629df4-4765-0214-bd40-fbb96542941f")!
	static let random = Self("0d7a5bfb-4850-098e-1821-d989bbfd58a8")!
	
	var isFree: Bool {
		self == Self.standard || self == Self.random
	}
}

extension AssetCollection {
	func resolveSkin(_ level: WeaponSkin.Level.ID) -> ResolvedLevel? {
		self[skinsByLevelID[level]]
	}
	
	subscript(path: WeaponSkin.Level.Path?) -> ResolvedLevel? {
		guard
			let path,
			let weapon = weapons[path.weapon]
		else { return nil }
		let skin = weapon.skins[path.skinIndex]
		let level = skin.levels[path.levelIndex]
		return .init(weapon: weapon, skin: skin, level: level, levelIndex: path.levelIndex)
	}
}

struct ResolvedLevel: Identifiable {
	var weapon: WeaponInfo
	var skin: WeaponSkin
	var level: WeaponSkin.Level
	var levelIndex: Int
	
	var id: WeaponSkin.Level.ID { level.id }
	
	var displayIcon: AssetImage? {
		skin.chromas.first?.fullRender ?? level.displayIcon ?? skin.displayIcon
	}
	
	var displayName: String {
		level.displayName ?? skin.displayName
	}
	
	func chroma(_ id: WeaponSkin.Chroma.ID) -> WeaponSkin.Chroma? {
		skin.chromas.firstElement(withID: id)
	}
}

struct WeaponStats: Codable {
	var fireRate: Double
	var magazineSize: Int
	var runSpeedMultiplier: Double
	var equipTime: TimeInterval
	var reloadTime: TimeInterval
	var firstBulletAccuracy: Double
	var shotgunPelletCount: Int
	var wallPenetration: WallPenetration
	var feature: Feature?
	/// automatic unless specified otherwise
	var fireMode: FireMode?
	var altFireMode: AltFireMode?
	var damageRanges: [DamageRange]
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		try fireRate = container.decodeValue(forKey: .fireRate)
		try magazineSize = container.decodeValue(forKey: .magazineSize)
		try runSpeedMultiplier = container.decodeValue(forKey: .runSpeedMultiplier)
		try equipTime = container.decodeValue(forKey: .equipTime)
		try reloadTime = container.decodeValue(forKey: .reloadTime)
		try firstBulletAccuracy = container.decodeValue(forKey: .firstBulletAccuracy)
		try shotgunPelletCount = container.decodeValue(forKey: .shotgunPelletCount)
		try wallPenetration = container.decodeValue(forKey: .wallPenetration)
		try feature = container.decodeValueIfPresent(forKey: .feature)
		try fireMode = container.decodeValueIfPresent(forKey: .fireMode)
		try damageRanges = container.decodeValue(forKey: .damageRanges)
		
		// > i made it type safe!
		// > what did it cost?
		// > everything…
		if let altFireMode = try? container.decode(AltFireMode.self, forKey: .altFireMode) {
			self.altFireMode = altFireMode
		} else {
			let apiContainer = try decoder.container(keyedBy: APICodingKeys.self)
			let altFireType = try apiContainer.decodeIfPresent(AltFireType.self, forKey: .altFireType)
			
			switch altFireType {
			case nil:
				altFireMode = nil
			case .aimDownSights?:
				altFireMode = .aimDownSights(
					try apiContainer.decodeValue(forKey: .adsStats)
					??? DecodingError.dataCorruptedError(
						forKey: .adsStats, in: apiContainer,
						debugDescription: "Expected ADS stats based on alt fire type."
					)
				)
			case .shotgun?:
				altFireMode = .shotgun(
					try apiContainer.decodeValue(forKey: .altShotgunStats)
					??? DecodingError.dataCorruptedError(
						forKey: .altShotgunStats, in: apiContainer,
						debugDescription: "Expected alt shotgun stats based on alt fire type."
					)
				)
			case .airBurst?:
				altFireMode = .airBurst(
					try apiContainer.decodeValue(forKey: .airBurstStats)
					??? DecodingError.dataCorruptedError(
						forKey: .airBurstStats, in: apiContainer,
						debugDescription: "Expected air burst stats based on alt fire type."
					)
				)
			case let type?:
				throw DecodingError.dataCorruptedError(
					forKey: .altFireType, in: apiContainer,
					debugDescription: "Unknown alt fire type: \(type)"
				)
			}
		}
	}
	
	private enum CodingKeys: String, CodingKey {
		case fireRate
		case magazineSize
		case runSpeedMultiplier
		case equipTime = "equipTimeSeconds"
		case reloadTime = "reloadTimeSeconds"
		case firstBulletAccuracy
		case shotgunPelletCount
		case wallPenetration
		case feature
		case fireMode
		case altFireMode
		case damageRanges
	}
	
	private enum APICodingKeys: String, CodingKey {
		case altFireType
		case adsStats
		case altShotgunStats
		case airBurstStats
	}
	
	struct WallPenetration: NamespacedID {
		static let high = Self("High")
		static let medium = Self("Medium")
		static let low = Self("Low")
		
		static let namespace = "EWallPenetrationDisplayType"
		var rawValue: String
	}
	
	struct Feature: NamespacedID {
		/// Rate of fire increases over time (Ares, Odin).
		static let rateOfFireIncrease = Self("ROFIncrease")
		static let silenced = Self("Silenced")
		static let dualZoom = Self("DualZoom")
		
		static let namespace = "EWeaponStatsFeature"
		var rawValue: String
	}
	
	struct FireMode: NamespacedID {
		static let semiAutomatic = Self("SemiAutomatic")
		
		static let namespace = "EWeaponFireModeDisplayType"
		var rawValue: String
	}
	
	struct DamageRange: Codable {
		var start, end: Int
		var damageToHead: Double
		var damageToBody: Double
		var damageToLegs: Double
		
		private enum CodingKeys: String, CodingKey {
			case start = "rangeStartMeters"
			case end = "rangeEndMeters"
			case damageToHead = "headDamage"
			case damageToBody = "bodyDamage"
			case damageToLegs = "legDamage"
		}
	}
	
	private struct AltFireType: NamespacedID {
		static let aimDownSights = Self("ADS")
		static let airBurst = Self("AirBurst")
		static let shotgun = Self("Shotgun")
		
		static let namespace = "EWeaponAltFireDisplayType"
		var rawValue: String
	}
}

enum AltFireMode: Codable {
	case aimDownSights(ADSStats)
	/// bullets burst into pellets in midair (Bucky)
	case airBurst(AirBurstStats)
	/// works like a shotgun (Classic right-click)
	case shotgun(ShotgunStats)
	
	struct ADSStats: Codable {
		var zoomMultiplier: Double
		var fireRate: Double
		var runSpeedMultiplier: Double
		/// number of bullets in a burst (Stinger, Bulldog)
		var burstCount: Int
		var firstBulletAccuracy: Double
	}
	
	struct AirBurstStats: Codable {
		var pelletCount: Int
		var detonationDistance: Double
		
		private enum CodingKeys: String, CodingKey {
			case pelletCount = "shotgunPelletCount"
			case detonationDistance = "burstDistance"
		}
	}
	
	struct ShotgunStats: Codable {
		var pelletCount: Int
		var rateOfFire: Double
		
		private enum CodingKeys: String, CodingKey {
			case pelletCount = "shotgunPelletCount"
			case rateOfFire = "burstRate"
		}
	}
}
