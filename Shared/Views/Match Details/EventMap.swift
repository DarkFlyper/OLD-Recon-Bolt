import SwiftUI
import CGeometry

struct EventMap: View {
	let matchData: MatchViewData
	let roundData: RoundData
	let magnificationScale = 3.0
	
	@State var isZoomedIn = false
	
	@Environment(\.verticalSizeClass) private var verticalSizeClass
	@Environment(\.assets) private var assets
	
	var body: some View {
		if let map = assets?.maps[matchData.details.matchInfo.mapID] {
			MagnifiableView {
				MapImage.minimap(map.id)
					.overlay(markersOverlay(in: map))
					.background(Material.ultraThin)
					.cornerRadius(16)
			} onMagnifyToggle: { isZoomedIn = $0 }
			.zIndex(1)
			.frame(maxHeight: verticalSizeClass == .compact ? 300 : nil)
		}
	}
	
	@Namespace private var markers
	
	func markersOverlay(in map: MapInfo) -> some View {
		GeometryReader { geometry in
			/*
			VStack {
				Text("hi")
				ForEach(roundData.interpolatedLocations()) { location in
					//Text(verbatim: "\(location)")
					Text(verbatim: "\(map.convert(location.position))")
					//Text(verbatim: "\(map.convert(location.position).in(geometry.size))")
				}
			}
			.font(.footnote)
			//.foregroundStyle(.secondary)
			.background(Material.ultraThinMaterial)
			.opacity(0.5)
			.frame(maxWidth: .infinity)
			*/
			
			//let allLocations = roundData.events.flatMap(\.playerLocations)
			//let allLocations = roundData.events[2].playerLocations
			
			ForEach(roundData.interpolatedLocations()) { location in
			//ForEach(allLocations.indexed(), id: \.index) { _, location in
				let isActor = location.id == roundData.currentEvent?.event.actor
				Group {
					if location.isDead {
						Image(systemName: "xmark")
					} else if let angle = location.angle {
						Image("MapPlayer")
							.foregroundStyle(isActor ? .primary : .secondary)
							.rotationEffect(.radians(angle))
					} else {
						Image(systemName: "circle")
							.foregroundStyle(isActor ? .primary : .secondary)
					}
				}
				.fixedSize()
				.background {
					if isZoomedIn {
						AgentImage.icon(location.agentID)
							.frame(width: 24, height: 24)
							.offset(x: 0, y: -24)
					}
				}
				.matchedGeometryEffect(id: location.id, in: markers)
				.foregroundColor(location.relativeColor)
				.shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
				.font(.system(size: 12).bold())
				.scaleEffect(isZoomedIn ? 1.5 / magnificationScale : 1)
				.position(map.convert(location.position) * geometry.size)
			}
		}
		//.rotationEffect(.degrees(90))
		//.scaleEffect(y: -1)
	}
}

#if DEBUG
struct EventMap_Previews: PreviewProvider {
	static var previews: some View {
		ScrollView {
			let matchData = PreviewData.singleMatchData
			let roundData = RoundData(round: 6, in: PreviewData.singleMatchData)
		EventMap(
			matchData: matchData,
			roundData: roundData
		)
			
			VStack(spacing: 4) {
				ForEach(roundData.events) { event in
					EventRow(event: event, matchData: matchData, roundData: .constant(roundData))
				}
			}
		}
			.padding()
			.inEachColorScheme()
	}
}
#endif
