import SwiftUI
import ValorantAPI

struct EventRow: View, Animatable {
	let event: PositionedEvent
	let matchData: MatchViewData
	@Binding var roundData: RoundData
	
	@ScaledMetric private var rowHeight = 40
	
	private var roundEvent: RoundEvent { event.event }
	
	var body: some View {
		HStack(spacing: 0) {
			roundEvent.formattedTime()
				.padding(8)
				.foregroundColor(event.relativeColor)
			
			HStack(spacing: 8) {
				if let kill = roundEvent as? Kill {
					killContent(for: kill)
				} else if let bombEvent = roundEvent as? BombEvent {
					bombEventContent(for: bombEvent)
				} else {
					fatalError("unknown event!")
				}
			}
		}
		.frame(height: rowHeight)
		.background {
			let proximity = roundData.proximity(of: event)
			event.relativeColor?.opacity(0.25 + pow(proximity, 1.3) * 0.4)
		}
		.cornerRadius(6)
		.onTapGesture {
			withAnimation {
				roundData.currentPosition = event.position
			}
		}
	}
	
	@ViewBuilder
	private func killContent(for kill: Kill) -> some View {
		let damageSource = kill.finishingDamage.source
		let damageType = kill.finishingDamage.type
		
		icon {
			if damageType == .bomb {
				iconImage(name: "Spike")
					.foregroundColor(.white)
			} else {
				let player = matchData.players[event.event.actor]!
				AgentImage.icon(player.agentID)
					.dynamicallyStroked(radius: 1, color: .white)
			}
		}
		
		let killer = matchData.players[kill.killer]!
		Group {
			// no switch in view builders yet :(
			if damageType == .bomb {
				Text("Exploded")
					.fontWeight(.medium)
			} else if damageType == .weapon, let weaponID = Weapon.ID(damageSource.lowercased()) {
				WeaponImage.killStreamIcon(weaponID)
					.scaleEffect(x: -1, y: 1, anchor: .center)
					.padding(4)
			} else if damageType == .melee {
				WeaponImage.killStreamIcon(.melee)
					.scaleEffect(x: -1, y: 1, anchor: .center)
					.padding(4)
			} else if damageType == .ability {
				if let abilityIndex = abilityIndices[damageSource] {
					let agent = killer.agentID
					AgentImage.ability(agent, abilityIndex: abilityIndex)
				} else {
					Text("<Unknown Ability>")
						.foregroundStyle(.secondary)
				}
			} else {
				Text("<Unknown Type>")
					.foregroundStyle(.secondary)
			}
		}
		.frame(maxWidth: .infinity)
		
		let victim = matchData.players[kill.victim]!
		icon {
			AgentImage.icon(victim.agentID)
				.dynamicallyStroked(radius: 1, color: .white)
				.background(matchData.relativeColor(of: victim))
		}
	}
	
	@ViewBuilder
	private func bombEventContent(for bombEvent: BombEvent) -> some View {
		icon {
			let player = matchData.players[event.event.actor]!
			AgentImage.icon(player.agentID)
				.dynamicallyStroked(radius: 1, color: .white)
		}
		
		Text("Spike \(bombEvent.isDefusal ? "Defused" : "Planted")")
			.fontWeight(.medium)
			.frame(maxWidth: .infinity)
		
		icon {
			iconImage(name: bombEvent.isDefusal ? "Defuse" : "Spike")
				.foregroundColor(.white)
		}
		.aspectRatio(1, contentMode: .fit)
	}
	
	private func iconImage(name: String) -> some View {
		Image("\(name) Icon")
			.resizable()
			.padding(4)
			.foregroundStyle(.thickMaterial)
	}
	
	func icon<Content: View>(@ViewBuilder content: () -> Content) -> some View {
		content()
			.aspectRatio(1, contentMode: .fit)
			.fixedSize(horizontal: true, vertical: false)
			.background(event.relativeColor)
	}
}

// TODO: this is not a pretty solution. Should probably better type decoded JSON?
private let abilityIndices = [
	"Ability1": 0,
	"Ability2": 1,
	"GrenadeAbility": 2,
	"Ultimate": 3,
	"Passive": 4,
]
