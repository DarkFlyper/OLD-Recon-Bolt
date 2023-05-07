import SwiftUI
import Algorithms

struct AgentInfoView: View {
	let agent: AgentInfo
	
	@State var fullscreenImages: AssetImageCollection?
	@State var activeAbilitySlot = AgentInfo.Ability.Slot.grenade // first ability
	@Namespace private var segmentNamespace
	
	var body: some View {
		ScrollViewReader { scrollView in
			ScrollView {
				VStack(spacing: 16) {
					portrait
						.onTapGesture { fullscreenImages = [agent.fullPortrait, agent.displayIcon] }
					
					Group {
						descriptionBox
						abilitiesBox(scrollView: scrollView)
					}
					.padding()
					.background(Color.secondaryGroupedBackground)
				}
			}
			.background(Color.groupedBackground)
			.coordinateSpace(name: "fixed")
		}
		.lightbox(for: $fullscreenImages)
		.navigationBarTitleDisplayMode(.inline)
	}
	
	@ViewBuilder
	var portrait: some View {
		let height: CGFloat = 500.0
		GeometryReader { geometry in
			let absoluteFrame = geometry.frame(in: .named("fixed"))
			let yOffset: CGFloat = -absoluteFrame.minY
			let yProgress: CGFloat = yOffset / height
			
			portraitImage
				.scaleEffect(1 - (0.25 * yProgress))
				.offset(y: 0.75 * yOffset)
				.background {
					textBackground
						.padding(.top, -64)
					// this looks ridiculous but it feels right ok
						.blur(radius: 16 * yProgress)
						.opacity(1.0 - 0.5 * yProgress)
						.offset(y: 0.4 * yOffset)
						.scaleEffect(1 + 0.1 * yProgress)
						.blendMode(.plusDarker)
				}
				.overlay(alignment: .top) {
					codeNameLabel
						.frame(height: 44)
						.offset(y: -44 + yOffset)
				}
			.padding(.bottom)
			.mask(alignment: .bottom) {
				Rectangle().frame(height: 1500)
			}
			.background {
				gradient
					.padding(.top, yOffset)
			}
			.navigationTitle(yOffset > 0 ? agent.displayName : "")
		}
		.frame(height: height)
	}
	
	var portraitImage: some View {
		AgentImage.fullPortrait(agent.id)
		// roundabout way to ignore the horizontal size of the image, since it's mostly transparent on the sides
			.frame(width: 2000)
			.frame(width: 1)
			.frame(maxWidth: .infinity)
	}
	
	var codeNameLabel: some View {
		Text("\"\(agent.developerName)\"")
			.foregroundStyle(.secondary)
			.font(.title3)
			.foregroundColor(.white)
			.blendMode(.plusLighter)
	}
	
	var textBackground: some View {
		agent.background.view(renderingMode: .template)
			.foregroundColor(.black)
			.opacity(0.15)
	}
	
	@ViewBuilder
	var gradient: some View {
		let colors = agent.backgroundGradientColors.reversed().map { $0.wrappedValue ?? .clear }
		LinearGradient(
			stops: zip(colors, [0, 0.4, 0.8, 1]).map(Gradient.Stop.init),
			startPoint: .top,
			endPoint: .bottom
		)
		.overlay(alignment: .top) {
			let height: CGFloat = 1000
			colors.first!.frame(height: height).offset(y: -height)
		}
		.padding(.top, -160)
	}
	
	var descriptionBox: some View {
		VStack(spacing: 16) {
			HStack {
				agent.role.displayIcon
					.view(renderingMode: .template)
					.frame(height: 16)
				
				Text(agent.role.displayName)
					.fontWeight(.medium)
			}
			
			Divider()
			
			alignedMultilineText(agent.description)
		}
	}
	
	@ViewBuilder
	func abilitiesBox(scrollView: ScrollViewProxy) -> some View {
		let boxID = "ability box"
		VStack(spacing: 20) {
			HStack(spacing: 0) {
				ForEach(agent.abilitiesInOrder, id: \.slot) { ability in
					let isActive = activeAbilitySlot == ability.slot
					icon(for: ability)
						.frame(height: 24)
						.padding(8)
						.mask(Capsule())
						.contentShape(Capsule())
						.background {
							if isActive {
								Capsule()
									.matchedGeometryEffect(id: 0, in: segmentNamespace)
									.blendMode(.destinationOut)
							}
						}
						.padding(2)
						.foregroundColor(isActive ? .accentColor : .primary)
						.onTapGesture {
							withAnimation {
								activeAbilitySlot = ability.slot
								scrollView.scrollTo(boxID, anchor: .bottom)
							}
						}
				}
			}
			.background(Capsule().opacity(0.1))
			.compositingGroup()
			
			VStack(spacing: 8) {
				let ability = agent.ability(activeAbilitySlot)!
				
				Text(ability.displayName)
					.font(.headline)
					.animation(nil, value: activeAbilitySlot)
				
				alignedMultilineText(ability.description)
			}
		}
		.id(boxID)
	}
	
	func alignedMultilineText(_ text: String) -> some View {
		Text(text)
			.frame(maxWidth: .infinity, alignment: .leading)
	}
	
	@ViewBuilder
	func icon(for ability: AgentInfo.Ability) -> some View {
		if let icon = ability.displayIcon {
			icon.view(renderingMode: .template)
		} else {
			Text(ability.slot.rawValue)
				.font(.caption)
				.fontWeight(.semibold)
				.padding(.horizontal, 4)
		}
	}
}

#if DEBUG
struct AgentInfoView_Previews: PreviewProvider, PreviewProviderWithAssets {
	static func previews(assets: AssetCollection) -> some View {
		NavigationView {
			NavigationLink("Example" as String, isActive: .constant(true)) {
				AgentInfoView(agent: assets.agents[.harbor]!)
			}
		}
	}
}
#endif
