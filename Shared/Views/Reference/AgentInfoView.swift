import SwiftUI
import Algorithms

struct AgentInfoView: View {
	let agent: AgentInfo
	
	@State var activeAbilitySlot = AgentInfo.Ability.Slot.grenade // first ability
	@Namespace private var segmentNamespace
	
	var body: some View {
		ScrollViewReader { scrollView in
			ScrollView {
				VStack(spacing: 16) {
					portrait
					
					Group {
						descriptionBox
						abilitiesBox(scrollView: scrollView)
					}
					.padding()
					.background(Color.secondaryGroupedBackground)
				}
				.animation(.default, value: activeAbilitySlot)
			}
			.background(Color.groupedBackground)
		}
		.navigationBarTitleDisplayMode(.inline)
	}
	
	@ViewBuilder
	var portrait: some View {
		VStack(spacing: 32) {
			VStack {
				Text(agent.displayName)
					.font(.system(.largeTitle, design: .default).smallCaps())
					.fontWeight(.semibold)
					.textCase(.uppercase)
				Text("\"\(agent.developerName)\"")
					.foregroundStyle(.secondary)
					.font(.title3)
			}
			.foregroundColor(.white)
			.blendMode(.plusLighter)
			
			AgentImage.fullPortrait(agent.id)
				.frame(maxHeight: 400)
		}
		.padding(.vertical)
		.background {
			let colors = agent.backgroundGradientColors.reversed().map { $0.wrappedValue ?? .clear }
			LinearGradient(
				stops: zip(colors, [0, 0.4, 0.8, 1]).map(Gradient.Stop.init),
				startPoint: .top,
				endPoint: .bottom
			)
			.overlay(alignment: .top) {
				let height: CGFloat = 1024
				colors.first!.frame(height: height).offset(y: -height)
			}
			.padding(.top, -160)
		}
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
							activeAbilitySlot = ability.slot
							withAnimation {
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
		AgentInfoView(agent: assets.agents[.harbor]!)
			.withToolbar()
	}
}
#endif
