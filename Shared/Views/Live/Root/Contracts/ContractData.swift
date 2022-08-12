import ValorantAPI

struct ContractData {
	var contract: Contract
	var info: ContractInfo
	var cumulativeXP: [Int]
	var levels: [Level]
	
	var totalXP: Int { cumulativeXP.last ?? 0 }
	var levelNumber: Int { contract.levelReached }
	var isComplete: Bool { levelNumber >= levels.count }
	
	var nextLevel: Level? {
		levels.elementIfValid(at: levelNumber)
	}
	
	var currentLevelCompletion: Double {
		guard let nextLevel else { return 1 }
		return Double(contract.progressionTowardsNextLevel) / Double(nextLevel.info.xp)
	}
	
	init(contract: Contract, info: ContractInfo) {
		self.contract = contract
		self.info = info
		let levelInfos = info.content.chapters.flatMap(\.levels)
		self.cumulativeXP = levelInfos.map(\.xp).reductions(0, +)
		let ranges = zip(cumulativeXP, cumulativeXP.dropFirst()).map(..<)
		self.levels = zip(levelInfos, ranges).enumerated().map { index, level in
			let (info, range) = level
			return Level(index: index, info: info, xpRange: range)
		}
	}
	
	struct Level: Identifiable {
		var index: Int
		var id: Int { number }
		var number: Int { index + 1 }
		
		var info: ContractInfo.Level
		var xpRange: Range<Int>
	}
}
