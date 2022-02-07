import SwiftUI
import ValorantAPI
import HandyOperators

struct PartyInfoBox: View {
	var userID: User.ID
	var party: Party
	
	@Environment(\.valorantLoad) private var load
	@State var isChangingQueue = false
	
	var body: some View {
		GroupBox {
			ForEach(party.members) { member in
				PartyMemberRow(party: party, member: member, userID: userID)
			}
			
			Divider()
			
			HStack {
				Text(party.matchmakingData.queueID.name)
					.font(.headline)
				
				Spacer()
				
				ZStack {
					Menu("Change Queue") {
						ForEach(party.eligibleQueues, id: \.self) { queue in
							Button(queue.name) {
								changeQueue(to: queue, in: party.id)
							}
						}
					}
					.disabled(isChangingQueue)
					
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
		if let entryTime = party.queueEntryTime {
			queueTimer(entryTime: entryTime)
			
			AsyncButton("Cancel Matchmaking") {
				await load {
					try await $0.leaveMatchmaking(in: party.id)
				}
			}
		} else {
			AsyncButton("Find Match") {
				await load {
					try await $0.joinMatchmaking(in: party.id)
				}
			}
			.disabled(!party.members.allSatisfy(\.isReady))
		}
	}
	
	private static let queueTimeFormatter = DateComponentsFormatter() <- {
		$0.zeroFormattingBehavior = .pad
		$0.allowedUnits = [.minute, .second]
	}
	
	func queueTimer(entryTime: Date) -> some View {
		TimelineView(.periodic(from: entryTime, by: 1)) { context in
			let time = Self.queueTimeFormatter.string(from: context.date.timeIntervalSince(entryTime))!
			Text("Finding match… (\(time))")
		}
	}
	
	func changeQueue(to queue: QueueID, in party: Party.ID) {
		Task {
			isChangingQueue = true
			defer { isChangingQueue = false }
			await load {
				try await $0.changeQueue(to: queue, in: party)
			}
		}
	}
	
	struct PartyMemberRow: View {
		let party: Party
		let member: Party.Member
		let userID: User.ID
		@State var isSettingReady = false
		
		@LocalData var memberUser: User?
		
		@Environment(\.valorantLoad) private var load
		
		var body: some View {
			HStack {
				PlayerCardImage.small(member.identity.cardID)
					.frame(width: 48)
					.mask(RoundedRectangle(cornerRadius: 4, style: .continuous))
				
				VStack(alignment: .leading) {
					HStack {
						if let memberUser = memberUser {
							HStack {
								Text(memberUser.gameName)
								Text("#\(memberUser.tagLine)")
									.foregroundColor(.secondary)
							}
						} else {
							Text("Member")
								.foregroundColor(.secondary)
						}
					}
					
					if member.isReady {
						Text("Ready")
							.foregroundColor(.secondary)
					} else {
						Text("Not Ready")
							.fontWeight(.medium)
							.foregroundColor(.secondary)
					}
				}
				
				Spacer()
				
				if member.id != userID {
					NavigationLink(destination: MatchListView(userID: member.id, user: memberUser)) {
						Image(systemName: "person.crop.circle.fill")
							.padding(.horizontal, 4)
					}
				} else {
					if isSettingReady {
						ProgressView()
					} else {
						Toggle("Ready", isOn: .init(get: { member.isReady }, set: setReady(to:)))
							.labelsHidden()
					}
				}
			}
			.withLocalData($memberUser, id: member.id, shouldAutoUpdate: true)
		}
		
		func setReady(to isReady: Bool) {
			Task {
				isSettingReady = true
				defer { isSettingReady = false }
				await load {
					try await $0.setReady(to: isReady, in: party.id)
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
				PartyInfoBox(userID: PreviewData.userID, party: PreviewData.party)
					.padding()
			}
			
			previewBox {
				PartyInfoBox(userID: PreviewData.userID, party: PreviewData.party <- {
					$0.members[0].isReady = false
					$0.members[1].isReady = true
					$0.queueEntryTime = .init(timeIntervalSinceNow: -35)
				})
				.padding()
			}
		}
		.inEachColorScheme()
    }
	
	static func previewBox<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
		RefreshableBox(title: "Party Info", refreshAction: {}) {
			Divider()
			content()
		}
		.forPreviews()
	}
}
#endif
