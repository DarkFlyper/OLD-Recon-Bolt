import SwiftUI
import ValorantAPI

// avoid polluting the global namespace
enum Stats {
	struct WeaponLabel: View {
		static var overrides: [Weapon.ID: LocalizedStringKey] = [
			.init("3de32920-4a8f-0499-7740-648a5bf95470")!: "Golden Gun",
			.init("856d9a7e-4b06-dc37-15dc-9d809c37cb90")!: "Headhunter (Chamber)",
			.init("39099fb5-4293-def4-1e09-2e9080ce7456")!: "Tour de Force (Chamber)",
			.init("95336ae4-45d4-1032-cfaf-6bad01910607")!: "Overdrive (Neon)",
		]
		
		var weapon: Weapon.ID
		
		@Environment(\.assets) private var assets
		
		var body: some View {
			if let weapon = assets?.weapons[weapon] {
				Text(weapon.displayName)
			} else if let override = Self.overrides[weapon] {
				Text(override)
			} else {
				Text("Unknown Weapon", comment: "Stats: label for a weapon that the app doesn't know for some reason")
					.foregroundStyle(.secondary)
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
