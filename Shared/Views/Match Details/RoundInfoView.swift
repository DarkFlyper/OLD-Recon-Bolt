import SwiftUI
import ValorantAPI
import CGeometry
import HandyOperators

struct RoundInfoContainer: View {
	let matchData: MatchViewData
	
	@State var roundNumber = 0
	@State var roundData: RoundData? = nil
	
	@Environment(\.horizontalSizeClass) var horizontalSizeClass
	
	var body: some View {
		ScrollView {
			VStack(spacing: 0) {
				roundChooser
					.padding(.vertical)
				
				if let roundData = Binding($roundData) {
					Divider()
					
					RoundInfoView(matchData: matchData, roundData: roundData)
						.padding(.vertical)
				}
			}
			.padding(.horizontal)
			.clipped() // keep the map zoom in bounds
		}
		.onAppear(perform: updateRoundData)
		.onDisappear {
			ReviewManager.registerUsage(points: 20)
			ReviewManager.requestReviewIfAppropriate()
		}
		.onChange(of: roundNumber) { _ in updateRoundData() }
		.navigationTitle(Text("Round Details", comment: "Round Details: title"))
		.navigationBarTitleDisplayMode(.inline)
	}
	
	private func updateRoundData() {
		guard roundNumber != roundData?.result.number else { return }
		roundData = .init(round: roundNumber, in: matchData)
	}
	
	var roundChooser: some View {
		HStack {
			let roundCount = matchData.details.roundResults.count
			
			roundStepButton(step: -1)
			
			Spacer()
			
			Text("Round \(roundNumber + 1) of \(roundCount)", comment: "Round Details: header")
				.font(.headline)
				.fontWeight(.medium)
			
			Spacer()
			
			roundStepButton(step: +1)
		}
	}
	
	func roundStepButton(step: Int) -> some View {
		Button {
			roundNumber += step
		} label: {
			Image(systemName: step > 0 ? "chevron.forward" : "chevron.backward")
				.frame(maxWidth: .infinity)
				.aspectRatio(1, contentMode: .fit)
				.padding(8)
				.background {
					Circle()
						.opacity(0.2)
				}
		}
		.disabled(!matchData.details.roundResults.indices.contains(roundNumber + step))
	}
}

struct RoundInfoView: View {
	let matchData: MatchViewData
	
	@Binding var roundData: RoundData
	
	@ScaledMetric private var rowHeight = 40
	
	var body: some View {
		VStack {
			EventMap(matchData: matchData, roundData: roundData)
			
			VStack {
				EventTimeline(matchData: matchData, roundData: $roundData)
				
				formattedTime(millis: Int(roundData.currentTime * 1000), includeMillis: true)
			}
			
			eventList
		}
	}
	
	var eventList: some View {
		VStack(spacing: 0) {
			ForEach(roundData.events.indexed(), id: \.element.id) { index, event in
				// how long ago this event was (0 for current and future events)
				let distance = max(0, Double(roundData.currentIndex - index) + roundData.progress)
				// how strongly to apply perspective scale
				let tanBase: Double = 5
				let distanceScale: Double = atan2(tanBase, distance + 1) / atan(tanBase)
				let spacing = 4 * distanceScale
				// how much of its usual vertical space the row itself receives
				let heightFactor = roundData.currentPosition < event.position ? 1 : roundData.proximity(of: event)
				
				EventRow(event: event, matchData: matchData, opacity: distanceScale, roundData: $roundData)
					.frame(height: rowHeight)
					.scaleEffect(distanceScale, anchor: .top)
					.padding(.bottom, (heightFactor - 1) * rowHeight + spacing)
					.zIndex(event.position)
			}
		}
		.drawingGroup()
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
	let secondsPart = "\(seconds)".zeroPadded(toLength: 2)
	let minutes = inSeconds / 60
	
	HStack(spacing: 0) {
		if includeMillis {
			let millisPart = "\(millis % 1000)".zeroPadded(toLength: 3)
			Text("\(minutes):\(secondsPart).\(millisPart)", comment: "Time Formatting: minutes, seconds, & milliseconds (used in round details view)")
				.foregroundStyle(.secondary)
		} else {
			Text("\(minutes):\(secondsPart)", comment: "Time Formatting: minutes & seconds (used in round details view)")
		}
	}
	.monospacedDigit()
}

extension String {
	func zeroPadded(toLength length: Int) -> Self {
		let toPad = length - count
		guard toPad > 0 else { return self }
		return .init(repeating: "0", count: toPad) + self
	}
}

extension RoundEvent {
	func formattedTime() -> AnyView {
		AnyView(Recon_Bolt.formattedTime(millis: roundTimeMillis))
	}
}

#if DEBUG
struct RoundInfoView_Previews: PreviewProvider {
	static var previews: some View {
		let matchData = PreviewData.singleMatchData
		let roundData = RoundData(round: 12, in: matchData) <- {
			let eventNumber = 8
			let progress = 0.6
			$0.currentPosition = (1 - progress) * $0.events[eventNumber].position
			+ progress * $0.events[eventNumber + 1].position
		}
		
		RoundInfoContainer(matchData: matchData, roundNumber: roundData.result.number, roundData: roundData)
			.withToolbar()
	}
}
#endif
