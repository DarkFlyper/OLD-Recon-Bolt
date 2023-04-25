import SwiftUI
import ValorantAPI

struct EventRow: View, Animatable {
	let event: PositionedEvent
	let matchData: MatchViewData
	var opacity: Double = 1
	
	@Binding var roundData: RoundData
	
	private var roundEvent: RoundEvent { event.event }
	
	var body: some View {
		let proximity = roundData.proximity(of: event)
		
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
		.background {
			event.relativeColor?.opacity(0.25 + pow(proximity, 1.3) * 0.25)
		}
		.opacity(opacity)
		.background {
			Rectangle()
				.blendMode(.destinationOut)
				.opacity(event.position > roundData.currentPosition ? proximity : 1)
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
		let damageType = kill.finishingDamage.type
		
		icon {
			if damageType == .bomb {
				iconImage(name: "Spike")
			} else {
				let player = matchData.player(event.event.actor!)
				AgentImage.icon(player.agentID!)
					.dynamicallyStroked(radius: 1, color: .white)
			}
		}
		
		let killer = matchData.player(kill.killer)
		Group {
			// no switch in view builders yet :(
			if damageType == .bomb {
				Text("Exploded", comment: "Round Details: killed by spike")
					.fontWeight(.medium)
			} else if damageType == .weapon {
				if let weaponID = kill.finishingDamage.weapon {
					WeaponImage.killStreamIcon(weaponID)
						.scaleEffect(x: -1, y: 1, anchor: .center)
						.padding(4)
				} else {
					Text("Unknown Weapon", comment: "Round Details: killed by unknown/unspecified weapon")
						.foregroundStyle(.secondary)
				}
			} else if damageType == .melee {
				WeaponImage.killStreamIcon(.melee)
					.scaleEffect(x: -1, y: 1, anchor: .center)
					.padding(4)
			} else if damageType == .ability {
				let slotName = kill.finishingDamage.remappedAbilitySlot
				if let slot = AgentInfo.Ability.Slot(rawValue: slotName) {
					AgentImage.ability(killer!.agentID!, slot: slot)
				} else {
					Text("Unknown Ability", comment: "Round Details: killed by unknown ability")
						.foregroundStyle(.secondary)
				}
			} else {
				Text("Unknown Type", comment: "Round Details: killed by unknown damage source/type")
					.foregroundStyle(.secondary)
			}
		}
		.frame(maxWidth: .infinity)
		
		let victim = matchData.player(kill.victim)
		icon {
			AgentImage.icon(victim.agentID!)
				.dynamicallyStroked(radius: 1, color: .white)
				.background(matchData.relativeColor(of: victim))
		}
	}
	
	@ViewBuilder
	private func bombEventContent(for bombEvent: BombEvent) -> some View {
		icon {
			let player = matchData.player(event.event.actor!)
			AgentImage.icon(player.agentID!)
				.dynamicallyStroked(radius: 1, color: .white)
		}
		
		Group {
			if bombEvent.isDefusal {
				Text("Spike Defused", comment: "Round Details: Spike Event")
			} else {
				Text("Spike Planted", comment: "Round Details: Spike Event")
			}
		}
		.font(.body.weight(.medium))
		.frame(maxWidth: .infinity)
		
		icon {
			iconImage(name: bombEvent.isDefusal ? "Defuse" : "Spike")
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

extension Kill.Damage {
	var weapon: Weapon.ID? {
		type == .weapon ? Weapon.ID(source.lowercased()) : nil
	}
}
