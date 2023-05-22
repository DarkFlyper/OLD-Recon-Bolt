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
		.mocked(error: FakeError.blankPreview)
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
		var location: Location?
		let result: Result<Value, Error>
		do {
			guard await Managers.store.ownsProVersion else {
				throw WidgetError.needProVersion
			}
			
			await Managers.assets.tryLoadAssets()
			
			let accountID = try configuration.accountID()
			link.account = accountID
			let account = try await Managers.accounts.getAccount(for: accountID)
			
			guard await !account.client.getSession().hasExpired else {
				throw APIError.sessionExpired(mfaRequired: true)
			}
			
			location = account.location
			if let version = await Managers.assets.assets?.version.riotClientVersion {
				account.setClientVersion(version)
			}
			
			let assets = try await Managers.assets.assets ??? FetchError.noAssets
			let config = try await GameConfigManager().config(for: account.location)
			??? FetchError.noConfig(account.location)
			var context = FetchingContext(
				client: account.client,
				configuration: configuration,
				context: timelineContext,
				assets: assets,
				seasons: assets.seasons.with(config),
				link: link
			)
			let value = try await fetchValue(in: &context)
			link = context.link
			result = .success(value)
		} catch {
			print(error)
			result = .failure(error)
		}
		
		return .init(date: .now, info: result, location: location, configuration: configuration, link: link)
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
			return String(localized: "Widgets require Recon Bolt Pro!", table: "Errors")
		}
	}
}

enum FetchError: Error, LocalizedError {
	case noAssets
	case noConfig(Location)
	
	var errorDescription: String? {
		switch self {
		case .noAssets:
			return String(localized: "Missing Assets!", table: "Errors")
		case .noConfig(let location):
			return String(localized: "Missing game configuration data for \(location.name) region!", table: "Errors")
		}
	}
}

struct FetchContext<Intent: INIntent> {
	let client: ValorantClient
	let configuration: Intent
	let context: TimelineProviderContext
	let assets: AssetCollection
	let seasons: SeasonCollection.Accessor
	var link: WidgetLink
}
