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
		TimelineView(.periodic(from: .now, by: 1)) { context in
			Text(Self.formatter.string(from: context.date, to: target)!)
				.monospacedDigit()
		}
	}
}

#if DEBUG
struct CountdownText_Previews: PreviewProvider {
	static var previews: some View {
		CountdownText(target: .init(timeIntervalSinceNow: 1000))
			.padding()
			.previewLayout(.sizeThatFits)
	}
}
#endif
