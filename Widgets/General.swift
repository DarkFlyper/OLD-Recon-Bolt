import SwiftUI
import WidgetKit

enum Managers {
	@MainActor static let accounts = AccountManager()
	@MainActor static let assets = AssetManager()
	@MainActor static let images = ImageManager()
	@MainActor static let store = InAppStore(isReadOnly: true)
	@MainActor static let gameConfig = GameConfigManager()
}

extension AssetImage {
	func resolved() async -> Image? {
		if let existing = AssetImage.preloaded[self] {
			return existing
		} else {
			return await Managers.images.awaitImage(for: self).map(Image.init)
		}
	}
	
	func preload() async {
		AssetImage.preloaded[self] = await resolved()
	}
}

extension IntentConfiguration {
	static func preloading<Provider: FetchingIntentTimelineProvider>(
		kind: String,
		intent: Intent.Type = Intent.self,
		provider: Provider,
		supportedFamilies: WidgetFamily...,
		content: @escaping (Provider.Entry) -> Content
	) -> some WidgetConfiguration where Intent == Provider.Intent {
		Self(
			kind: kind,
			intent: Intent.self,
			provider: PreloadingIntentTimelineProvider(
				wrapped: provider,
				supportedFamilies: supportedFamilies,
				content: content
			),
			content: content
		)
		.supportedFamilies(supportedFamilies)
	}
}

struct PreloadingIntentTimelineProvider<
	Wrapped: FetchingIntentTimelineProvider,
	Content: View
>: FetchingIntentTimelineProvider {
	typealias Intent = Wrapped.Intent
	
	let wrapped: Wrapped
	let supportedFamilies: [WidgetFamily]
	let content: (Wrapped.Entry) -> Content
	
	func fetchValue(in context: inout Wrapped.FetchingContext) async throws -> Wrapped.Value {
		let value = try await wrapped.fetchValue(in: &context)
		await preloadImages {
			ForEach(supportedFamilies, id: \.self) {
				content(.init(info: .success(value)))
					.environment(\.adjustedWidgetFamily, $0)
			}
		}
		return value
	}
}

extension EnvironmentValues {
	var adjustedWidgetFamily: WidgetFamily {
		get { self[FamilyKey.self] ?? widgetFamily }
		set { self[FamilyKey.self] = newValue }
	}
	
	enum FamilyKey: EnvironmentKey {
		static let defaultValue: WidgetFamily? = nil
	}
}

@MainActor
func preloadImages<Content: View>(@ViewBuilder usedIn views: () -> Content) async {
	ImageRenderer(content: ZStack(content: views)).render { _, _ in }
	
	_ = await AssetImage.used.concurrentMap { image in
		await image.preload()
	}
}

extension Sequence {
	func concurrentMap<T>(_ transform: (Element) async throws -> T) async throws -> [T] {
		try await withoutActuallyEscaping(transform) { transform in
			try await withThrowingTaskGroup(of: (Int, T).self) { group in
				var count = 0
				for (i, element) in self.enumerated() {
					count += 1
					group.addTask {
						(i, try await transform(element))
					}
				}
				
				// maintain order
				var transformed: [T?] = .init(repeating: nil, count: count)
				for try await (i, newElement) in group {
					transformed[i] = newElement
				}
				return transformed.map { $0! }
			}
		}
	}
	
	func concurrentMap<T>(_ transform: (Element) async -> T) async -> [T] {
		await withoutActuallyEscaping(transform) { transform in
			await withTaskGroup(of: (Int, T).self) { group in
				var count = 0
				for (i, element) in self.enumerated() {
					count += 1
					group.addTask {
						(i, await transform(element))
					}
				}
				
				// maintain order
				var transformed: [T?] = .init(repeating: nil, count: count)
				for await (i, newElement) in group {
					transformed[i] = newElement
				}
				return transformed.map { $0! }
			}
		}
	}
}
