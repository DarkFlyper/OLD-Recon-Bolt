import SwiftUI
import WidgetKit
import HandyOperators

enum Managers {
	@AutoReloadedManager static var accounts = AccountManager()
	@AutoReloadedManager static var assets = AssetManager() <- {
		if let assets = $0.assets {
			// autoclosure, not called until accessed, so no need to worry about initialization order
			images.setVersion(assets.version)
		}
	}
	@AutoReloadedManager static var store = InAppStore(isReadOnly: true)
	@MainActor static let images = ImageManager()
}

/// keeps a manager around for a short time to function as a singleton within one operation,
/// but clears/reloads it afterwards to make sure it matches the newest data from the app
@MainActor
@propertyWrapper
final class AutoReloadedManager<Value> {
	private let makeValue: () -> Value
	private var cache: (Value, Date)?
	private let reloadDelay: TimeInterval = 30
	
	var wrappedValue: Value {
		if let (value, date) = cache, -date.timeIntervalSinceNow < reloadDelay {
			return value
		} else {
			let value = makeValue()
			cache = (value, .now)
			return value
		}
	}
	
	init(wrappedValue: @escaping @autoclosure @MainActor () -> Value) {
		makeValue = wrappedValue
	}
}

extension AssetImage {
	@MainActor
	func resolved() async -> Image? {
		if let existing = AssetImage.preloaded[self] {
			return existing
		} else {
			return await Managers.images.awaitImage(for: self).map(Image.init)
		}
	}
	
	@MainActor
	func preload() async {
		AssetImage.preloaded[self] = await resolved()
	}
}

extension IntentConfiguration {
	static func preloading<Provider: FetchingIntentTimelineProvider>(
		kind: WidgetKind,
		intent: Intent.Type = Intent.self,
		provider: Provider,
		content: @escaping (Provider.Entry) -> Content
	) -> some WidgetConfiguration where Intent == Provider.Intent {
		Self(
			kind: kind.rawValue,
			intent: Intent.self,
			provider: PreloadingIntentTimelineProvider(
				wrapped: provider,
				content: content
			),
			content: content
		)
	}
}

struct PreloadingIntentTimelineProvider<
	Wrapped: FetchingIntentTimelineProvider,
	Content: View
>: FetchingIntentTimelineProvider {
	typealias Intent = Wrapped.Intent
	
	let wrapped: Wrapped
	let content: (Wrapped.Entry) -> Content
	
	func fetchValue(in context: inout Wrapped.FetchingContext) async throws -> Wrapped.Value {
		let value = try await wrapped.fetchValue(in: &context)
		let entry = Wrapped.Entry(
			date: .now,
			info: .success(value),
			location: context.client.location,
			configuration: context.configuration,
			link: .init()
		)
		let family = context.context.family
		await preloadImages {
			content(entry).environment(\.adjustedWidgetFamily, family)
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
	AssetImage.used = []
	ImageRenderer(content: ZStack(content: views)).render { _, _ in }
	let used = AssetImage.used
	
	_ = await used.concurrentMap { image in
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
