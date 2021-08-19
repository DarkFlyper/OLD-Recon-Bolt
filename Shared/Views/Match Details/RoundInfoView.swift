import SwiftUI
import ValorantAPI
import CGeometry
import HandyOperators

struct RoundInfoView: View {
	let matchData: MatchViewData
	let roundNum = 6
	
	@State var roundData: RoundData
	
	init(data: MatchViewData) {
		self.matchData = data
		let round = data.details.roundResults[roundNum]
		self._roundData = .init(initialValue: RoundData(round, matchData: data))
	}
	
	var body: some View {
		VStack {
			Text("Round \(roundData.result.number + 1)")
			
			Text(roundData.id.uuidString)
			
			EventTimeline(matchData: matchData, roundData: $roundData)
			
			VStack(spacing: 4) {
				ForEach(roundData.events) { event in
					EventRow(event: event, matchData: matchData, roundData: $roundData)
				}
			}
		}
		.padding()
	}
}

// I tried to get DateComponentsFormatter working as I needed, but it just doesn't cover my use case:
// • you can't pad to minutes with just one zero (.dropTrailing appears to work but drops the seconds if they're zero)
// • you can't have it show milliseconds (only… nanoseconds)
// this solution isn't very localization-friendly unfortunately
private func formattedTime(millis: Int, includeMillis: Bool = false) -> Text {
	let inSeconds = millis / 1000
	let seconds = inSeconds % 60
	let secondsPadding = seconds < 10 ? "0" : ""
	let secondsPart = "\(secondsPadding)\(seconds)"
	
	let minutes = inSeconds / 60
	let roughPart = "\(minutes):\(secondsPart)"
	
	let string = includeMillis ? "\(roughPart).\(millis % 1000)" : roughPart
	return Text(string).monospacedDigit()
}

extension RoundEvent {
	func formattedTime() -> Text {
		Recon_Bolt.formattedTime(millis: roundTimeMillis)
	}
}

#if DEBUG
struct RoundInfoView_Previews: PreviewProvider {
	static var previews: some View {
		RoundInfoView(data: PreviewData.singleMatchData)
			.inEachColorScheme()
	}
}
#endif
