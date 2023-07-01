import Foundation
import ValorantAPI

struct ResolvedContracts {
	let details: ContractDetails
	let daily: DailyTicketProgress
	let assets: AssetCollection?
	
	let weeklies: [MissionWithInfo]
	let upcomingMissions: [MissionInfo]?
	let queuedUpWeeklies, futureWeeklies: [MissionInfo]?
	
	var dailyRefresh: Date?
	
	var weeklyRefresh: Date? {
		details.missionMetadata.weeklyRefillTime
	}
	
	init(progress: ContractsProgress, assets: AssetCollection?, seasons: SeasonCollection.Accessor?) {
		self.details = progress.contracts
		self.assets = assets
		
		if progress.daily.remainingTime > 0 {
			self.daily = progress.daily
			self.dailyRefresh = progress.dailyRefresh
		} else {
			self.daily = .zero
			self.dailyRefresh = nil
		}
		
		let missions: [MissionWithInfo] = details.missions
			.map { .init(mission: $0, info: assets?.missions[$0.id]) }
		
		self.weeklies = missions
		
		self.upcomingMissions = seasons.flatMap { [details] in
			assets?.upcomingMissions(for: details, seasons: $0)
		}
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
	func upcomingMissions(for details: ContractDetails, seasons: SeasonCollection.Accessor) -> [MissionInfo]? {
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

struct MissionWithInfo: Identifiable {
	var mission: Mission
	var info: MissionInfo?
	
	var id: Mission.ID { mission.id }
}

struct ResolvedMission {
	var name: String
	var progress: Int?
	var toComplete: Int
	
	init(info: MissionInfo, mission: Mission?, assets: AssetCollection?) {
		let (objectiveID, progress) = mission?.objectiveProgress.onlyElement() ?? (nil, nil)
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
		?? "Unnamed Mission"
	}
}

private extension Date {
	func adding(days: Double) -> Self {
		addingTimeInterval(days * 24 * 3600) // don't need to consider leap seconds or DST for this because it's pretty rough anyway
	}
}
