import SwiftUI
import HandyOperators

struct CountdownText: View {
	var target: Date
	
	private static let formatter = DateComponentsFormatter() <- {
		// DateComponentsFormatter gives us more control than RelativeDateTimeFormatter
		$0.unitsStyle = .positional
		$0.allowedUnits = [.day, .hour, .minute, .second]
	}
	
	@State private var refresher = 0
	
	var body: some View {
		Text(Self.formatter.string(from: .now, to: target)!)
			.id(refresher)
			.monospacedDigit()
			.task {
				while !Task.isCancelled {
					await Task.sleep(seconds: 1, tolerance: 0.05)
					refresher += 1
				}
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
