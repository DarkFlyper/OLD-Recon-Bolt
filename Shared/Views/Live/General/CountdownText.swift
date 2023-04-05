import SwiftUI
import HandyOperators

struct CountdownText: View {
	var target: Date
	
	private static let formatter = DateComponentsFormatter() <- {
		// DateComponentsFormatter gives us more control than RelativeDateTimeFormatter
		$0.unitsStyle = .positional
		$0.allowedUnits = [.day, .hour, .minute, .second]
	}
	
	var body: some View {
		if target >= .now, target.timeIntervalSinceNow < 24 * 3600, #available(iOS 16.0, *) {
			// this works better for sub-minute times, but shows days as hours, so we'll only use it for targets less than a day away
			Text(timerInterval: Date.now...target)
				.monospacedDigit()
		} else {
			TimelineView(.periodic(from: .now, by: 1)) { context in
				Text(Self.formatter.string(from: context.date, to: target)!)
					.monospacedDigit()
			}
		}
	}
}

#if DEBUG
struct CountdownText_Previews: PreviewProvider {
	static var previews: some View {
		VStack(spacing: 20) {
			ForEach([10, 100, 1000, 10_000, 100_000], id: \.self) { (length: TimeInterval) in
				CountdownText(target: .init(timeIntervalSinceNow: length))
			}
		}
		.padding()
		.previewLayout(.sizeThatFits)
	}
}
#endif
