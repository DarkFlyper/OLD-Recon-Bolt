import SwiftUI
import Algorithms

struct AgentInfoView: View {
	let agent: AgentInfo
	
	@State var activeAbilityIndex = 0
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
				.animation(.default, value: activeAbilityIndex)
			}
			.background(Color.groupedBackground)
			.ignoresSafeArea(.container, edges: .top)
		}
		//.navigationTitle(agent.displayName)
	}
	
	var portrait: some View {
		let backgroundColor = Color.secondaryGroupedBackground
		return AgentImage.bustPortrait(agent.id)
			.frame(maxHeight: 300)
			.padding(.top, 100)
			.background {
				LinearGradient(
					colors: [backgroundColor.opacity(0), backgroundColor],
					startPoint: .top,
					endPoint: .bottom
				)
			}
	}
	
	var descriptionBox: some View {
		VStack(spacing: 16) {
			HStack {
				Text(agent.displayName)
					.fontWeight(.semibold)
				Text("\"\(agent.developerName)\"")
					.foregroundStyle(.secondary)
			}
			.font(.title3)
			
			if let tags = agent.characterTags {
				HStack {
					ForEach(tags, id: \.self) { tag in
						Text(tag)
							.font(.caption)
							.padding(.horizontal, 4)
							.padding(4)
							.blendMode(.destinationOut)
							.background(Capsule())
							.compositingGroup()
							.opacity(0.75)
					}
				}
			}
			
			HStack {
				agent.role.displayIcon
					.imageOrPlaceholder(renderingMode: .template)
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
				ForEach(agent.reorderedAbilities.indexed(), id: \.index) { index, ability in
					let isActive = activeAbilityIndex == index
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
							activeAbilityIndex = index
							withAnimation {
								scrollView.scrollTo(boxID, anchor: .bottom)
							}
						}
				}
			}
			.background(Capsule().opacity(0.1))
			.compositingGroup()
			
			VStack(spacing: 8) {
				let ability = agent.ability(activeAbilityIndex)
				
				Text(ability.displayName)
					.font(.headline)
					.animation(nil, value: activeAbilityIndex)
				
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
			icon.imageOrPlaceholder(renderingMode: .template)
		} else {
			Text(ability.slot)
				.font(.caption)
				.fontWeight(.semibold)
				.padding(.horizontal, 4)
		}
	}
}

#if DEBUG
struct AgentInfoView_Previews: PreviewProvider {
	static var previews: some View {
		AgentInfoView(agent: AssetManager.forPreviews.assets!.agents[.sova]!)
			.withToolbar()
			.inEachColorScheme()
	}
}
#endif
