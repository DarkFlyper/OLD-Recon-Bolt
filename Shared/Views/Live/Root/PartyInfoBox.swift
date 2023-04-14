import SwiftUI
import ValorantAPI
import HandyOperators

struct PartyInfoBox: View {
	var userID: User.ID
	@Binding var party: Party
	
	@Environment(\.valorantLoad) private var load
	@State var isChangingQueue = false
	@State var isConfirmingMatchakingStart = false
	
	var member: Party.Member {
		party.members.firstElement(withID: userID)
		?? party.members.first! // can be nil while switching accounts
	}
	
	var body: some View {
		GroupBox {
			ForEach(party.members) { member in
				PartyMemberRow(party: $party, member: member, userID: userID)
			}
			
			Divider()
			
			HStack {
				QueueLabel(queue: party.matchmakingData.queueID)
					.font(.headline)
				
				Spacer()
				
				ZStack {
					Menu("Change Queue") {
						ForEach(party.eligibleQueues ?? [], id: \.self) { queue in
							Button {
								changeQueue(to: queue, in: party.id)
							} label: {
								QueueLabel(queue: queue)
							}
						}
					}
					.disabled(isChangingQueue)
					.disabled(!member.isOwner)
					.disabled(party.state == .inMatchmaking)
					.disabled(party.eligibleQueues == nil)
					
					if isChangingQueue {
						ProgressView()
					}
				}
			}
			
			Divider()
			
			matchmakingSection
				.buttonStyle(.bordered)
		}
	}
	
	@ViewBuilder
	private var matchmakingSection: some View {
		switch party.state {
		case .inMatchmaking:
			queueTimer(entryTime: party.queueEntryTime)
			
			AsyncButton("Cancel Matchmaking") {
				await load {
					party = try await $0.leaveMatchmaking(in: party.id)
				}
			}
		case .default:
			Button("Find Match") {
				isConfirmingMatchakingStart = true
			}
			.disabled(!party.members.allSatisfy(\.isReady))
			.disabled(!member.isOwner)
			.confirmationDialog(
				"Start Matchmaking?",
				isPresented: $isConfirmingMatchakingStart,
				titleVisibility: .visible
			) {
				AsyncButton("Find Match") {
					await load {
						party = try await $0.joinMatchmaking(in: party.id)
					}
				}
			} message: {
				Text("Please make sure you are ready to play by the time the game starts!")
			}
		default:
			EmptyView()
		}
	}
	
	private static let queueTimeFormatter = DateComponentsFormatter() <- {
		$0.zeroFormattingBehavior = .pad
		$0.allowedUnits = [.minute, .second]
	}
	
	func queueTimer(entryTime: Date) -> some View {
		TimelineView(.periodic(from: entryTime, by: 1)) { context in
			let time = Self.queueTimeFormatter.string(from: context.date.timeIntervalSince(entryTime))!
			Text("Finding match… (\(time))", comment: "Party Box: placeholder shows time spent in queue")
		}
	}
	
	func changeQueue(to queue: QueueID, in partyID: Party.ID) {
		Task {
			isChangingQueue = true
			defer { isChangingQueue = false }
			await load {
				party = try await $0.changeQueue(to: queue, in: partyID)
			}
		}
	}
	
	struct PartyMemberRow: View {
		@Binding var party: Party
		let member: Party.Member
		let userID: User.ID
		@State var isSettingReady = false
		
		@LocalData var memberUser: User?
		@LocalData var summary: CareerSummary?
		
		@Environment(\.valorantLoad) private var load
		
		init(party: Binding<Party>, member: Party.Member, userID: User.ID) {
			self._party = party
			self.member = member
			self.userID = userID
			self._memberUser = .init(id: member.id)
			self._summary = .init(id: member.id)
		}
		
		var body: some View {
			let iconSize = 48.0
			
			HStack {
				PlayerCardImage.small(member.identity.cardID)
					.frame(width: iconSize, height: iconSize)
					.mask(RoundedRectangle(cornerRadius: 4, style: .continuous))
				
				VStack(alignment: .leading) {
					HStack {
						if let memberUser {
							HStack {
								Text(memberUser.gameName)
								Text("#\(memberUser.tagLine)")
									.foregroundColor(.secondary)
							}
						} else {
							Text("Member", comment: "Party Box: shown when member's name is not yet loaded")
								.foregroundColor(.secondary)
						}
					}
					
					if member.isReady {
						Text("Ready", comment: "Party Box")
							.foregroundColor(.secondary)
					} else {
						Text("Not Ready", comment: "Party Box")
							.fontWeight(.medium)
							.foregroundColor(.secondary)
					}
				}
				
				Spacer()
				
				if member.id != userID {
					NavigationLink {
						MatchListView(userID: member.id)
					} label: {
						Image(systemName: "person.crop.circle.fill")
							.padding(.horizontal, 4)
					}
					
					RankInfoView(summary: summary, size: iconSize)
				} else {
					if isSettingReady {
						ProgressView()
					} else {
						Toggle(String(localized: "Ready", comment: "accessibility label"), isOn: Binding(
							get: { member.isReady },
							set: { setReady(to: $0) })
						)
						.labelsHidden()
					}
				}
			}
			.withLocalData($memberUser, id: member.id, shouldAutoUpdate: true)
			.withLocalData($summary, id: member.id, shouldAutoUpdate: true)
		}
		
		func setReady(to isReady: Bool) {
			Task {
				isSettingReady = true
				defer { isSettingReady = false }
				await load {
					party = try await $0.setReady(to: isReady, in: party.id)
				}
			}
		}
	}
}

#if DEBUG
struct PartyInfoBox_Previews: PreviewProvider {
	static var previews: some View {
		Group {
			previewBox {
				PartyInfoBox(userID: PreviewData.userID, party: .constant(PreviewData.party))
					.padding()
			}
			
			previewBox {
				PartyInfoBox(userID: PreviewData.userID, party: .constant(PreviewData.party <- {
					$0.members[0].isReady = false
					$0.members[1].isReady = true
					$0.queueEntryTime = .init(timeIntervalSinceNow: -35)
				}))
				.padding()
			}
		}
	}
	
	static func previewBox<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
		RefreshableBox(title: "\("Party")", isExpanded: .constant(true)) {
			Divider()
			content()
		} refresh: { _ in }
		.forPreviews()
	}
}
#endif
