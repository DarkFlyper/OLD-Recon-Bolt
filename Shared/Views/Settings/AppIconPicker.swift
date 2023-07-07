import SwiftUI

struct AppIconPicker: View {
	@ObservedObject var manager: AppIconManager
	@Environment(\.ownsProVersion) var ownsProVersion
	@State var selectionError: Error?
	
	var body: some View {
		List {
			Section {
				cell(for: .default)
			} header: {
				Text("Default Icon", comment: "App Icon Picker: section")
			}
			
			Section {
				cell(for: .proBlue)
				if isProud {
					cell(for: .prideDark)
				}
			} header: {
				Text("Pro Icons", comment: "App Icon Picker: section")
			} footer: {
				Text("The pro version lets you change the app icon! More icons might be coming in future updates.", comment: "App Icon Picker: section footer")
			}
			
			if isProud {
				Section {
					cell(for: .pride)
				} header: {
					Text("Special Icons", comment: "App Icon Picker: section")
				} footer: {
					Text("Special Icons are available year-round for Pro users, while free users can only select them during a certain time window.", comment: "App Icon Picker: section footer")
				}
			}
		}
		.navigationTitle("Choose App Icon")
		.alert(Text("Could not Change App Icon!"), for: $selectionError)
	}
	
	func cell(for icon: AppIcon) -> some View {
		let isAllowed = ownsProVersion || icon.isFree || isInSwiftUIPreview
		return AsyncButton {
			do {
				try await manager.select(icon)
			} catch {
				selectionError = error
			}
		} label: {
			HStack(spacing: 16) {
				AppIcon.Thumbnail(icon: icon)
				
				VStack(alignment: .leading, spacing: 4) {
					HStack {
						if !isAllowed {
							ProExclusiveBadge()
						}
						icon.name
							.font(.headline)
					}
					
					icon.description
						.font(.footnote)
				}
				.tint(.primary)
				
				Spacer()
				
				Image(systemName: "checkmark")
					.opacity(manager.currentIcon == icon ? 1 : 0)
			}
		}
		.disabled(!isAllowed)
	}
}

private let isProud = !Locale.current.identifier.starts(with: "ru_")

extension AppIcon {
	struct Thumbnail: View {
		var icon: AppIcon
		var size: CGFloat = 80
		
		var body: some View {
			let squircle = RoundedRectangle(cornerRadius: 0.2 * size, style: .continuous)
			return Image("app icons/\(icon.key ?? "AppIcon")")
				.resizable()
				.aspectRatio(contentMode: .fit)
				.mask { squircle }
				.overlay {
					squircle
						.strokeBorder(.white.opacity(0.1), lineWidth: 1)
						.blendMode(.plusLighter)
				}
				.shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
				.frame(width: size, height: size)
		}
	}
}

@MainActor
final class AppIconManager: ObservableObject {
	@Published private(set) var currentIcon = getCurrent()
	
	private static func getCurrent() -> AppIcon {
		let key = UIApplication.shared.alternateIconName
		return AppIcon.all.first { $0.key == key } ?? {
			print("unknown selected icon: \(key ?? "<nil>")")
			return .default
		}()
	}
	
	func select(_ icon: AppIcon) async throws {
		try await UIApplication.shared.setAlternateIconName(icon.key)
		currentIcon = icon
	}
}

struct AppIcon: Identifiable, Equatable {
	static let all = [`default`, pride, proBlue, prideDark]
	static let `default` = Self(
		key: nil, isFree: true,
		name: Text("Default", comment: "App Icon Name"),
		description: Text("The default look of Recon Bolt.", comment: "App Icon Description: default")
	)
	static let pride = Self(
		key: "AppIconPride", isFree: Calendar.current.date(.now, matchesComponents: .init(month: 6)), // free during pride month
		name: Text("Rainbow", comment: "App Icon Name"),
		description: Text("Celebrate LGBTQ Pride month with a colorful look! (Free during June)", comment: "App Icon Description: pride")
	)
	static let proBlue = Self(
		key: "AppIconProBlue", isFree: false,
		name: Text("Pro Blue", comment: "App Icon Name"),
		description: Text("Show off your pro status with an exclusive icon!", comment: "App Icon Description: pro blue")
	)
	static let prideDark = Self(
		key: "AppIconPrideDark", isFree: false,
		name: Text("Dark Rainbow", comment: "App Icon Name"),
		description: Text("Celebrate LGBTQ Pride month, but in dark!", comment: "App Icon Description: pride")
	)
	
	var key: String?
	var isFree: Bool
	var name: Text
	var description: Text
	
	var id: String {
		key ?? ""
	}
	
	static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.key == rhs.key
	}
}

#if DEBUG
struct AppIconPicker_Previews: PreviewProvider {
    static var previews: some View {
		AppIconPicker(manager: AppIconManager())
    }
}
#endif
