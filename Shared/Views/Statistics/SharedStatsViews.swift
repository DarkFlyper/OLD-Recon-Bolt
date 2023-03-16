import SwiftUI
import ValorantAPI

// avoid polluting the global namespace
enum Stats {
	struct QueueLabel: View {
		var queue: QueueID?
		
		@Environment(\.assets) private var assets
		
		var body: some View {
			if let queue = assets?.queues[queue ?? .custom] {
				Text(queue.name)
			} else {
				Text("Unknown Queue")
					.foregroundStyle(.secondary)
			}
		}
	}
	
	struct WeaponLabel: View {
		var weapon: Weapon.ID
		
		@Environment(\.assets) private var assets
		
		var body: some View {
			if let weapon = assets?.weapons[weapon] {
				Text(weapon.displayName)
			} else {
				Text("Unknown Weapon")
					.foregroundStyle(.secondary)
			}
		}
	}
	
	struct LabeledRow<Label: View, Value: View>: View {
		@ViewBuilder var label: Label
		@ViewBuilder var value: Value
		
		var body: some View {
			HStack {
				label
				Spacer()
				value.foregroundStyle(.secondary)
			}
		}
	}
	
	@available(iOS 16.0, *)
	struct DurationLabel: View {
		var duration: TimeInterval
		
		var body: some View {
			Text(Duration.seconds(duration), format: .units(
				allowed: [.days, .hours, .minutes],
				width: .abbreviated,
				maximumUnitCount: 2
			))
		}
	}
}
