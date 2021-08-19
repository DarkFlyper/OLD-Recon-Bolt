import SwiftUI
import ValorantAPI
import Algorithms
import CGeometry
import HandyOperators

struct RoundData: Animatable {
	let id = UUID()
	let result: RoundResult
	let events: [PositionedEvent]
	let bounds: ClosedRange<Double>
	var currentPosition: Double {
		didSet {
			currentPosition = max(bounds.lowerBound, min(bounds.upperBound, currentPosition))
			updateNeighbors()
		}
	}
	
	// TODO: get this working correctly (it currently has no effect)
	var animatableData: Double {
		get { currentPosition }
		set {
			currentPosition = newValue
			fatalError() // this isn't even called…
		}
	}
	
	private var currentEvent: PositionedEvent?
	private var nextEvent: PositionedEvent?
	private var progress: Double = 0 // progress between events
	
	init(_ result: RoundResult, matchData: MatchViewData) {
		self.result = result
		
		let events = result.eventsInOrder()
		
		let eventTimes = events.map(\.time)
		let intervals = ([0] + eventTimes).adjacentPairs().map { $1 - $0 }
		let totalTime = intervals.reduce(0, +)
		let staticFraction = 0.5 // how much of the total time is equally allocated to each interval (vs based on length)
		let dynamicFraction = 1 - staticFraction
		let baseLength = (staticFraction * totalTime) / Double(intervals.count)
		let adjustedLengths = intervals.map { dynamicFraction * $0 + baseLength }
		let positions = adjustedLengths.reductions(+)
		
		bounds = (positions.first ?? 0)...(positions.last ?? 0)
		
		self.events = zip(events, positions).map { event, position in
			PositionedEvent(event: event, matchData: matchData, position: position)
		}
		
		//self.currentPosition = positions.first ?? 0
		self.currentPosition = (positions[3] + positions[4]) / 2 // FIXME: revert—only for previews
		updateNeighbors()
	}
	
	private mutating func updateNeighbors() {
		guard !events.isEmpty else { return }
		let currentEvent = events.last { $0.position <= currentPosition }!
		self.currentEvent = currentEvent
		nextEvent = events.first { $0.position > currentPosition }
		
		if let next = nextEvent {
			let distance = next.position - currentEvent.position
			let offset = currentPosition - currentEvent.position
			progress = offset / distance
		} else {
			progress = 0
		}
	}
	
	func proximity(of event: PositionedEvent) -> Double {
		if event == currentEvent {
			return 1 - progress
		} else if event == nextEvent {
			return progress
		} else {
			return 0
		}
	}
	
	func interpolatedLocations() -> [DisplayedPlayerLocation] {
		guard let previous = currentEvent else { return [] }
		guard let next = nextEvent else { return previous.playerLocations }
		let nextLocations = Dictionary(values: next.playerLocations)
		return previous.playerLocations.map { location in
			if let nextLocation = nextLocations[location.id] {
				return location.interpolated(towards: nextLocation, progress: progress)
			} else {
				return location
			}
		}
	}
}

struct PositionedEvent: Identifiable, Equatable {
	let id = UUID()
	let event: RoundEvent
	let position: Double
	let playerLocations: [DisplayedPlayerLocation]
	let relativeColor: Color?
	
	init(event: RoundEvent, matchData: MatchViewData, position: Double) {
		self.event = event
		self.position = position
		
		self.playerLocations = .build {
			event.playerLocations.map(DisplayedPlayerLocation.init)
			
			// killed players aren't listed in the locations anymore, but we still want to show them and animate to them
			if let kill = event as? Kill {
				DisplayedPlayerLocation(
					id: kill.victim,
					isDead: true,
					position: .init(kill.victimPosition)
				)
			}
		}
		
		if let kill = event as? Kill, kill.finishingDamage.type == .bomb {
			self.relativeColor = .secondary
		} else {
			self.relativeColor = matchData.relativeColor(of: event.actor)
		}
	}
	
	static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.id == rhs.id
	}
}

struct DisplayedPlayerLocation: Identifiable {
	var id: Player.ID
	var isDead = false
	var position: CGPoint
	var angle: Double?
	
	func interpolated(towards end: Self, progress: Double) -> Self {
		self <- { $0.interpolate(towards: end, progress: progress) }
	}
	
	mutating func interpolate(towards end: Self, progress: Double) {
		assert(end.id == id)
		
		if let angle0 = angle, let angle1 = end.angle {
			let angleAverage = ((angle0 + angle1) / 2).truncatingAngle()
			// there are two correct averages—pick the one with less change.
			angle = abs(angleAverage - angle0).truncatingAngle() < .pi / 2
				? angleAverage
				: (angleAverage + .pi).truncatingAngle()
		} else {
			angle = angle ?? end.angle
		}
		
		position += (end.position - position) * progress
	}
}

private extension FloatingPoint {
	func truncatingAngle() -> Self {
		truncatingRemainder(dividingBy: 2 * .pi)
	}
}

extension DisplayedPlayerLocation {
	init(_ location: PlayerLocation) {
		self.id = location.subject
		self.position = .init(location.position)
		self.angle = location.angle
	}
}

extension RoundResult {
	func eventsInOrder() -> [RoundEvent] {
		.build {
			playerStats.flatMap(\.kills)
			plant.map { BombEvent(isDefusal: false, action: $0) }
			defusal.map { BombEvent(isDefusal: true, action: $0) }
		}
		.sorted(on: \.roundTimeMillis)
	}
}

protocol RoundEvent {
	var roundTimeMillis: Int { get }
	var time: TimeInterval { get }
	var actor: Player.ID { get }
	var playerLocations: [PlayerLocation] { get }
}

extension RoundEvent {
	var time: TimeInterval {
		TimeInterval(roundTimeMillis) / 1000
	}
}

extension Kill: RoundEvent {
	var actor: Player.ID { killer }
}

struct BombEvent: RoundEvent {
	var isDefusal: Bool // else plant
	var action: RoundResult.BombAction
	
	var roundTimeMillis: Int { action.roundTimeMillis }
	var actor: Player.ID { action.actor }
	var playerLocations: [PlayerLocation] { action.playerLocations }
}
