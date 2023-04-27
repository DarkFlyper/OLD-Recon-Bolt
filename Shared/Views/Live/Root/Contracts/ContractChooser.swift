import SwiftUI
import ValorantAPI

struct ContractChooser: View {
	var details: ContractDetails
	
	@Environment(\.valorantLoad) private var load
	@Environment(\.dismiss) private var dismiss
	@Environment(\.assets?.contracts) private var contracts
	
	var body: some View {
		let sorted = (contracts ?? [:]).values
			.filter { $0.content.relationType == .agent || $0.id == .freeAgents }
			.sorted(
				on: { $0.content.relationType?.rawValue ?? "zzz" }, // sort free agent contract to end
				then: \.displayName
			)
		
		ScrollView {
			VStack(spacing: 1) {
				ForEach(sorted) { info in
					let contract = details.contracts.firstElement(withID: info.id)
					?? .unprogressed(with: info.id)
					
					let data = ContractData(contract: contract, info: info)
					ContractRow(
						data: data,
						isActive: details.activeSpecialContract == info.id,
						activate: activateContract
					)
					.background(Color.secondaryGroupedBackground)
				}
			}
			.cornerRadius(20)
			.padding()
		}
		.background(Color.groupedBackground)
		.navigationTitle(Text("Choose a Contract", comment: "Contract Picker: title"))
	}
	
	@MainActor
	func activateContract(with id: Contract.ID) async {
		await load {
			try await $0.activateContract(id)
		}
		dismiss()
	}
	
	struct ContractRow: View {
		var data: ContractData
		var isActive: Bool
		var activate: (Contract.ID) async -> Void
		
		@State var isExpanded = false
		
		var body: some View {
			VStack {
				HStack {
					if let id = data.info.content.agentID {
						SquareAgentIcon(agentID: id)
							.frame(height: 48)
					}
					
					VStack(alignment: .leading) {
						Text(data.info.displayName.localizedCapitalized)
						
						Group {
							if isActive {
								Text("Active", comment: "Contract Picker")
									.foregroundColor(.accentColor)
							} else if data.isComplete {
								Text("Completed", comment: "Contract Picker")
							} else if let agent = data.info.content.agentID {
								if Inventory.starterAgents.contains(agent) {
									Text("Free Agent", comment: "Contract Picker")
								} else {
									if data.levelNumber >= 5 {
										Text("Agent Unlocked", comment: "Contract Picker")
									} else {
										Text("Agent Unlockable", comment: "Contract Picker")
									}
								}
							}
						}
						.foregroundStyle(.secondary)
					}
					
					Spacer()
					
					if isActive {
						Image(systemName: "checkmark")
							.foregroundColor(.accentColor)
					}
					
					if
						!data.isComplete,
						data.levelNumber < 5,
						let agent = data.info.content.agentID,
						!Inventory.starterAgents.contains(agent)
					{
						Image(systemName: "lock")
					}
					
					ContractLevelProgressView(data: data)
				}
				.opacity(data.isComplete ? 0.5 : 1)
				.font(.body.weight(isActive ? .medium : .regular))
				
				if isExpanded {
					ContractProgressBar(data: data)
					
					AsyncButton {
						await activate(data.info.id)
					} label: {
						Text("Activate", comment: "Contract Picker: button")
					}
					.buttonStyle(.bordered)
					.disabled(isActive || data.isComplete)
				}
			}
			.padding()
			.contentShape(Rectangle())
			.onTapGesture {
				withAnimation {
					isExpanded.toggle()
				}
			}
		}
	}
}

#if DEBUG
struct ContractChooser_Previews: PreviewProvider {
	static var previews: some View {
		ContractChooser(details: PreviewData.contractDetails)
			.withToolbar()
	}
}
#endif
