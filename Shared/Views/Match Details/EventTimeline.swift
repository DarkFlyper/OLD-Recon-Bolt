import SwiftUI
import ValorantAPI
import HandyOperators

struct EventTimeline: View {
	let matchData: MatchViewData
	@Binding var roundData: RoundData
	
	private let markerHeight = 10.0
	private let iconDistance = 16.0
	private let iconExtraDistance = 8.0
	private let iconSize = 20.0
	private let knobSize = 24.0
	
	var body: some View {
		let events = roundData.events
		if let firstEvent = events.first, let lastEvent = events.last {
			let heightFromBar = max(markerHeight, knobSize)
			let heightFromIcons = iconDistance + iconSize / 2
			
			GeometryReader { geometry in
				let barY = geometry.size.height - heightFromBar / 2
				
				let scaleFactor = geometry.size.width / lastEvent.position
				HStack(spacing: 0) {
					Rectangle().frame(width: 1, height: 6)
						.foregroundStyle(.secondary)
					Rectangle()
						.frame(width: scaleFactor * firstEvent.position - 1)
						.foregroundStyle(.secondary)
					Rectangle()
						.foregroundStyle(.secondary)
						.frame(width: scaleFactor * (roundData.currentPosition - firstEvent.position))
					Rectangle()
						.foregroundStyle(.tertiary)
						.foregroundColor(.primary)
				}
				.frame(height: 2)
				.position(x: geometry.size.width / 2, y: barY)
				.foregroundColor(.accentColor)
				
				ForEach(events) { event in
					eventCapsule(for: event)
						.position(x: scaleFactor * event.position, y: barY)
				}
				
				Circle()
					.fill(Color.white)
					.frame(width: knobSize, height: knobSize)
					.shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
					.position(x: scaleFactor * roundData.currentPosition, y: barY)
					.gesture(
						DragGesture(minimumDistance: 0, coordinateSpace: .named(CoordSpace.slider))
							.onChanged { updateCurrentPosition(to: $0.location.x, scaleFactor: scaleFactor) }
							.onEnded { _ in
								guard !isSnapping else { return }
								// snap to nearest event
								withAnimation(.default.speed(2)) {
									roundData.currentPosition = roundData.currentEvent?.position ?? 0
								}
							}
					)
			}
			.coordinateSpace(name: CoordSpace.slider)
			.compositingGroup()
			.frame(height: heightFromBar + heightFromIcons)
			.fixedSize(horizontal: false, vertical: true)
		}
	}
	
	private static let feedbackGenerator = UISelectionFeedbackGenerator()
	@State private var isSnapping = false
	
	private func updateCurrentPosition(to sliderPosition: Double, scaleFactor: Double) {
		Self.feedbackGenerator.prepare()
		
		let position = sliderPosition / scaleFactor
		let snapThreshold = 5.0
		let snapCandidate = roundData.events
			.map { (distance: abs($0.position - position), event: $0) }
			.sorted(on: \.distance)
			.prefix(1)
			.filter { $0.distance * scaleFactor < snapThreshold }
			.first
		
		let wasSnapping = isSnapping
		isSnapping = snapCandidate != nil
		roundData.currentPosition = snapCandidate?.event.position ?? position
		
		if isSnapping, !wasSnapping {
			Self.feedbackGenerator.selectionChanged()
		}
	}
	
	private func eventCapsule(for event: PositionedEvent) -> some View {
		let proximity = roundData.proximity(of: event)
		let extraDistance = proximity * iconExtraDistance
		
		return Capsule()
			.frame(width: 4, height: markerHeight)
			.fixedSize()
			.background {
				Capsule().padding(-1)
					.blendMode(.destinationOut)
			}
			.overlay {
				icon(for: event.event)
					.frame(width: iconSize, height: iconSize)
					.position(x: 2, y: -iconDistance - extraDistance)
			}
			.foregroundColor(event.relativeColor)
			.onTapGesture {
				withAnimation {
					roundData.currentPosition = event.position
				}
			}
	}
	
	@ViewBuilder
	private func icon(for event: RoundEvent) -> some View {
		if let kill = event as? Kill {
			let isVictimSelf = kill.victim == matchData.myself?.id
			Image(systemName: "xmark")
				.resizable()
				.symbolVariant(isVictimSelf ? .circle : .none)
				.padding(2)
		} else if let bombEvent = event as? BombEvent {
			Image("\(bombEvent.isDefusal ? "Defuse" : "Spike") Icon")
				.resizable()
		}
	}
	
	private enum CoordSpace: Hashable {
		case slider
	}
}

#if DEBUG
struct EventTimeline_Previews: PreviewProvider {
	static var previews: some View {
		Group {
			PreviewView(matchData: PreviewData.singleMatchData, roundData: PreviewData.roundData)
			PreviewView(matchData: PreviewData.singleMatchData, roundData: PreviewData.midRoundData)
		}
		.padding()
		.previewLayout(.sizeThatFits)
	}
	
	struct PreviewView: View {
		var matchData: MatchViewData
		@State var roundData: RoundData
		
		var body: some View {
			EventTimeline(matchData: matchData, roundData: $roundData)
		}
	}
}
#endif
