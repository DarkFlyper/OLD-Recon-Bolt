import WidgetKit
import Intents
import ValorantAPI
import HandyOperators

protocol AsyncIntentTimelineProvider: IntentTimelineProvider {
	func getSnapshot(for configuration: Intent, in context: Context) async -> Entry
	func getTimeline(for configuration: Intent, in context: Context) async -> Timeline<Entry>
}

extension AsyncIntentTimelineProvider {
	func getSnapshot(
		for configuration: Intent,
		in context: Context,
		completion: @escaping (Entry) -> Void
	) {
		Task {
			completion(await getSnapshot(for: configuration, in: context))
		}
	}
	
	func getTimeline(
		for configuration: Intent,
		in context: Context,
		completion: @escaping (Timeline<Entry>) -> Void
	) {
		Task {
			completion(await getTimeline(for: configuration, in: context))
		}
	}
}

protocol FetchingIntentTimelineProvider: AsyncIntentTimelineProvider
where Entry == FetchedTimelineEntry<Value, Intent>, Intent: FetchingIntent {
	associatedtype Value: FetchedTimelineValue
	
	typealias FetchingContext = FetchContext<Intent>
	
	func fetchValue(in context: inout FetchingContext) async throws -> Value
}

extension FetchingIntentTimelineProvider {
	func placeholder(in context: Context) -> Entry {
		.init(info: .failure(FakeError.blankPreview))
	}
	
	func getSnapshot(for configuration: Intent, in context: Context) async -> Entry {
		await getCurrentEntry(for: configuration, in: context)
	}
	
	func getTimeline(for configuration: Intent, in context: Context) async -> Timeline<Entry> {
		let entry = await getCurrentEntry(for: configuration, in: context)
		return Timeline(entries: [entry], policy: .after(entry.nextRefresh()))
	}
	
	func getCurrentEntry(for configuration: Intent, in timelineContext: Context) async -> Entry {
		var link = WidgetLink()
		let result: Result<Value, Error>
		do {
			await Managers.store.refreshFromDefaults()
			guard await Managers.store.ownsProVersion else {
				throw WidgetError.needProVersion
			}
			
			await Managers.assets.loadAssets()
			
			let account = try await configuration.loadAccount()
			link.account = account.session.userID
			if let version = await Managers.assets.assets?.version.riotClientVersion {
				account.setClientVersion(version)
			}
			
			let assets = try await Managers.assets.assets ??? FetchError.noAssets
			var context = FetchingContext(
				client: account.client,
				configuration: configuration,
				context: timelineContext,
				assets: assets,
				link: link
			)
			let value = try await fetchValue(in: &context)
			link = context.link
			result = .success(value)
		} catch {
			print(error)
			result = .failure(error)
		}
		return .init(date: .now, info: result, configuration: configuration, link: link)
	}
}

enum FakeError: Error, LocalizedError {
	case blankPreview
	
	var errorDescription: String? { "" }
}

enum WidgetError: Error, LocalizedError {
	case needProVersion
	
	var errorDescription: String? {
		switch self {
		case .needProVersion:
			return "Widgets require Recon Bolt Pro!"
		}
	}
}

enum FetchError: Error, LocalizedError {
	case noAssets
	
	var errorDescription: String? {
		switch self {
		case .noAssets:
			return "Missing Assets!"
		}
	}
}

struct FetchContext<Intent: INIntent> {
	let client: ValorantClient
	let configuration: Intent
	let context: TimelineProviderContext
	let assets: AssetCollection
	var link: WidgetLink
}
