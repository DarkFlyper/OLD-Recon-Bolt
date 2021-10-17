import SwiftUI
import ValorantAPI
import CGeometry
import HandyOperators

struct RoundInfoView: View {
	let matchData: MatchViewData
	
	@State var roundData: RoundData
	
	init(data: MatchViewData, roundNum: Int) {
		self.matchData = data
		self._roundData = .init(initialValue: RoundData(round: roundNum, in: data))
	}
	
	var body: some View {
		ScrollView {
			VStack {
				Text(roundData.id.uuidString)
				
				EventMap(matchData: matchData, roundData: roundData)
				
				formattedTime(millis: Int(roundData.currentTime * 1000), includeMillis: true)
				
				EventTimeline(matchData: matchData, roundData: $roundData)
				
				VStack(spacing: 4) {
					ForEach(roundData.events) { event in
						EventRow(event: event, matchData: matchData, roundData: $roundData)
					}
				}
			}
			.padding()
		}
		.clipped()
		.navigationTitle("Round \(roundData.result.number + 1)")
		.navigationBarTitleDisplayMode(.inline)
	}
}

// I tried to get DateComponentsFormatter working as I needed, but it just doesn't cover my use case:
// • you can't pad to minutes with just one zero (.dropTrailing appears to work but drops the seconds if they're zero)
// • you can't have it show milliseconds (only… nanoseconds)
// this solution isn't very localization-friendly unfortunately
@ViewBuilder
private func formattedTime(millis: Int, includeMillis: Bool = false) -> some View {
	let inSeconds = millis / 1000
	let seconds = inSeconds % 60
	let secondsPadding = seconds < 10 ? "0" : ""
	let secondsPart = "\(secondsPadding)\(seconds)"
	
	let minutes = inSeconds / 60
	let roughPart = "\(minutes):\(secondsPart)"
	
	//let string = includeMillis ? "\(roughPart).\(Text(millisPart).foregroundStyle(.secondary))" : roughPart
	HStack(spacing: 0) {
		Text(roughPart)
		if includeMillis {
			let millisPart = "\(millis % 1000)".padding(toLength: 3, withPad: "0", startingAt: 0)
			Text(".\(millisPart)").foregroundStyle(.secondary)
		}
	}
	.monospacedDigit()
}

extension RoundEvent {
	func formattedTime() -> AnyView {
		AnyView(Recon_Bolt.formattedTime(millis: roundTimeMillis))
	}
}

#if DEBUG
struct RoundInfoView_Previews: PreviewProvider {
	static var previews: some View {
		RoundInfoView(data: PreviewData.singleMatchData, roundNum: 6)
			.inEachColorScheme()
	}
}
#endif
