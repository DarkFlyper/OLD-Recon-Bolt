import SwiftUI
import WidgetKit
import ValorantAPI

protocol TimelineEntryView: View {
	associatedtype Value: FetchedTimelineValue
	associatedtype Intent: FetchingIntent
	associatedtype ValueView: View
	
	typealias Entry = FetchedTimelineEntry<Value, Intent>
	
	var entry: Entry { get }
	
	@ViewBuilder
	func contents(for value: Value) -> ValueView
}

extension TimelineEntryView {
	var body: some View {
		Group {
			switch entry.info {
			case .success(let info):
				contents(for: info)
			case .failure(let error):
				Text(error.localizedDescription)
					.foregroundColor(.secondary)
					.multilineTextAlignment(.center)
					.padding()
			}
		}
		.accentColor(Color("AccentColor"))
		.widgetURL(entry.link.makeURL())
	}
}

struct FetchedTimelineEntry<Value: FetchedTimelineValue, Intent: FetchingIntent>: TimelineEntry {
	var date = Date()
	var info: Result<Value, Error>
	var configuration = Intent()
	var link = WidgetLink()
	
	func nextRefresh() -> Date {
		do {
			return try info.get().nextRefresh
		} catch APIError.rateLimited(let retryAfter) {
			return .init(timeIntervalSinceNow: .init(retryAfter ?? 60))
		} catch is APIError {
			// TODO: trigger refresh from the app when this fails? might be hard to detect, but it might also be fine to just refresh on launch?
			return .init(timeIntervalSinceNow: 3600)
		} catch is URLError {
			return .init(timeIntervalSinceNow: 120) // likely connection failure; retry when connection is likely to be back
		} catch {
			return .init(timeIntervalSinceNow: 300) // decent default timeout
		}
	}
}

protocol FetchedTimelineValue {
	var nextRefresh: Date { get }
}
