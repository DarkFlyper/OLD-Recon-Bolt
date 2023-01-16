import Foundation
import ValorantAPI

struct ResolvedContracts {
	let details: ContractDetails
	let assets: AssetCollection?
	
	let dailies, weeklies, unknown: [MissionWithInfo]
	let upcomingMissions: [MissionInfo]?
	let queuedUpWeeklies, futureWeeklies: [MissionInfo]?
	
	var dailyRefresh: Date? {
		dailies.first?.mission.expirationTime
	}
	
	var weeklyRefresh: Date? {
		details.missionMetadata.weeklyRefillTime
	}
	
	init(details: ContractDetails, assets: AssetCollection?) {
		self.details = details
		self.assets = assets
		
		let missions: [MissionWithInfo] = details.missions
			.map { ($0, assets?.missions[$0.id]) }
		
		self.dailies = missions.filter { $0.info?.type == .daily }
		self.weeklies = missions.filter { $0.info?.type == .weekly }
		let covered = Set((dailies + weeklies).map(\.mission.id))
		self.unknown = missions.filter { !covered.contains($0.mission.id) }
		
		self.upcomingMissions = assets?.upcomingMissions(for: details)
		if let upcomingMissions {
			let now = Date.now
			let futureStart = upcomingMissions.firstIndex { $0.activationDate! > now }
			?? upcomingMissions.endIndex
			
			queuedUpWeeklies = Array(upcomingMissions.prefix(upTo: futureStart))
			futureWeeklies = Array(upcomingMissions.suffix(from: futureStart))
		} else {
			queuedUpWeeklies = nil
			futureWeeklies = nil
		}
	}
}

private extension AssetCollection {
	func upcomingMissions(for details: ContractDetails) -> [MissionInfo]? {
		// the weekly checkpoint is equal to the activation date of the last completed group of weeklies
		// so we'll figure that out and find all missions starting after that date
		
		// weekly checkpoint may still be in the last act—let's take the later of that and the current act's start
		let checkpointDate = [
			details.missionMetadata.weeklyCheckpoint?
				.adding(days: 7), // add one week to skip the completed group
			seasons.currentAct()?.timeSpan.start
		].compacted().max()
		guard let checkpointDate else { return nil }
		
		// shift forward by 3 days to skip the currently-active group and into the middle of the week
		// this also avoids issues with acts launching at different times in different regions, as well as DST
		let checkpoint = checkpointDate.adding(days: 3)
		
		return missions.values
			.filter { $0.type == .weekly }
		// all weeklies have activation dates
			.filter { $0.activationDate! > checkpoint }
			.sorted(on: \.activationDate!)
	}
}

typealias MissionWithInfo = (mission: Mission, info: MissionInfo?)

struct ResolvedMission {
	var name: String
	var progress: Int?
	var toComplete: Int
	
	init(info: MissionInfo, mission: Mission?, assets: AssetCollection?) {
		let (objectiveID, progress) = mission?.objectiveProgress.singleElement ?? (nil, nil)
		self.progress = progress
		let objectiveValue = info.objective(id: objectiveID)
		self.toComplete = objectiveValue?.value
		?? info.progressToComplete // this is incorrect for e.g. the "you or your allies plant or defuse spikes" one, where it's 1 while the objectives correctly list it as 5
		
		let objective = (objectiveID ?? objectiveValue?.objectiveID)
			.flatMap { assets?.objectives[$0] }
		
		self.name = objective?.directive?
			.valorantLocalized(number: toComplete)
		?? info.displayName
		?? info.title
		?? "<Unnamed Mission>"
	}
}

private extension Date {
	func adding(days: Double) -> Self {
		addingTimeInterval(days * 24 * 3600) // don't need to consider leap seconds or DST for this because it's pretty rough anyway
	}
}
