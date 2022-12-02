import SwiftUI

struct AppIconPicker: View {
	@ObservedObject var manager: AppIconManager
	@Environment(\.ownsProVersion) var ownsProVersion
	@State var selectionError: Error?
	
	var body: some View {
		List {
			Section("Default Icon") {
				cell(for: .default)
			}
			
			Section {
				cell(for: .proBlue)
			} header: {
				Text("Pro Icons")
			} footer: {
				Text("The pro version lets you change the app icon! More icons might be coming in future updates.")
			}
		}
		.navigationTitle("Choose App Icon")
		.alert("Could not Change App Icon!", for: $selectionError)
	}
	
	func cell(for icon: AppIcon) -> some View {
		let isAllowed = ownsProVersion || icon.key == nil || isInSwiftUIPreview
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
					Text(icon.name)
						.font(.headline)
					
					Text(icon.description)
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

extension AppIcon {
	struct Thumbnail: View {
		var icon: AppIcon
		var size: CGFloat = 80
		
		var body: some View {
			let squircle = RoundedRectangle(cornerRadius: 0.2 * size, style: .continuous)
			return Image("app icons/\(icon.key ?? "AppIcon")")
				.resizable()
				.aspectRatio(contentMode: .fit)
				.background(Color.gray)
				.mask { squircle }
				.overlay {
					squircle
						.strokeBorder(.white.opacity(0.1), lineWidth: 1)
						.blendMode(.plusLighter)
				}
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
	static let all = [`default`, proBlue]
	static let `default` = Self(key: nil, name: "Default", description: "The default look of Recon Bolt.")
	static let proBlue = Self(key: "AppIconProBlue", name: "Pro Blue", description: "Show off your pro status with an exclusive icon!")
	
	var key: String?
	var name: LocalizedStringKey
	var description: LocalizedStringKey
	
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
