import SwiftUI
import ValorantAPI

struct AccountSettingsView: View {
	@ObservedObject var accountManager: AccountManager
	
	@State var loginTarget: LoginTarget?
	@Environment(\.ownsProVersion) private var ownsProVersion
	
	var body: some View {
		Section {
			cells
		} header: {
			Text("Accounts")
		} footer: {
			legalBoilerplate
		}
		.sheet(item: $loginTarget) { target in
			let storedCredentals = accountManager.activeAccount?.session.credentials
			LoginForm(
				accountManager: accountManager,
				credentials: (target.shouldRestoreCredentials ? storedCredentals : nil) ?? .init()
			)
			.withLoadErrorAlerts()
		}
	}
	
	@ViewBuilder
	var cells: some View {
		if accountManager.activeAccount?.session.hasExpired == true {
			HStack {
				Text("Session expired!")
				Spacer()
				Button("Refresh") {
					loginTarget = .sessionRefresh
				}
				.font(.body.bold())
			}
		}
		
		if accountManager.storedAccounts.isEmpty {
			Text("Not signed in yet.")
			
			Button("Sign In") {
				loginTarget = .firstAccount
			}
			.font(.body.weight(.medium))
		} else {
			ForEach(accountManager.storedAccounts, id: \.self) { accountID in
				AccountCell(accountID: accountID, accountManager: accountManager)
			}
			.onDelete { accountManager.storedAccounts.remove(atOffsets: $0) }
			.onMove { accountManager.storedAccounts.move(fromOffsets: $0, toOffset: $1) }
			
			Button {
				loginTarget = .extraAccount
			} label: {
				Label {
					Text("Add another Account")
				} icon: {
					// the icon doesn't get tinted correctly if i don't do this…
					Image(systemName: "plus")
						.foregroundColor(ownsProVersion ? nil : .secondary)
				}
			}
			.disabled(!ownsProVersion)
		}
	}
	
	var legalBoilerplate: some View {
		Text("Recon Bolt is not endorsed by Riot Games and does not reflect the views or opinions of Riot Games or anyone officially involved in producing or managing Riot Games properties. Riot Games and all associated properties are trademarks or registered trademarks of Riot Games, Inc")
			.font(.footnote)
			.foregroundStyle(.secondary)
			.frame(maxWidth: .infinity, alignment: .leading)
	}
	
	enum LoginTarget: Hashable, Identifiable {
		case firstAccount
		case extraAccount
		case sessionRefresh
		
		var shouldRestoreCredentials: Bool {
			self != .extraAccount
		}
		
		var id: Self { self }
	}
	
	struct AccountCell: View {
		var accountID: User.ID
		@ObservedObject var accountManager: AccountManager
		@State var loadError: Error?
		
		@LocalData var user: User?
		@Environment(\.ownsProVersion) private var ownsProVersion
		
		var body: some View {
			let isActive = accountManager.activeAccount?.id == accountID
			let index = accountManager.storedAccounts.firstIndex(of: accountID)
			HStack {
				Button {
					withAnimation {
						do {
							try accountManager.toggleActive(accountID)
						} catch {
							print(error)
							loadError = error
						}
					}
				} label: {
					Label {
						HStack(spacing: 4) {
							if let user {
								Text(user.gameName).fontWeight(.semibold)
								Text("#\(user.tagLine)")
							} else {
								Text("Unknown Account")
							}
						}
						.tint(.primary)
					} icon: {
						Image(systemName: "checkmark")
							.opacity(isActive ? 1 : 0)
					}
				}
				.disabled((index ?? 0) > 0 && !ownsProVersion)
				
				Spacer()
			}
			.withLocalData($user, id: accountID, shouldAutoUpdate: true)
			.alert("Could not Load Account!", $error: $loadError)
			.deleteDisabled(isActive)
		}
	}
}
