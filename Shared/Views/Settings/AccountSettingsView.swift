import SwiftUI
import ValorantAPI

struct AccountSettingsView: View {
	@ObservedObject var accountManager: AccountManager
	
	@State var loginTarget: LoginTarget?
	@State var isConfirmingSignOut = false
	@Environment(\.ownsProVersion) private var ownsProVersion
	
	var body: some View {
		Group {
			Section {
				cells
			} header: {
				Text("Accounts", comment: "Settings: section")
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
			
			Section {
				if accountManager.activeAccount?.session.hasExpired == true {
					HStack {
						Text("Session expired!", comment: "Account Settings: shown when the current account's session has expired")
						Spacer()
						Button {
							loginTarget = .sessionRefresh
						} label: {
							Text("Refresh", comment: "Account Settings: button to refresh expired session")
						}
						.font(.body.bold())
					}
				}
				
				Button {
					isConfirmingSignOut = true
				} label: {
					Text("Sign Out of All Accounts", comment: "Account Settings: button")
				}
				.disabled(accountManager.storedAccounts.isEmpty)
				.confirmationDialog(
					Text("Are You Sure?", comment: "Account Settings: title for alert to confirm signing out of all accounts—not always visible; iOS decides when to show this"),
					isPresented: $isConfirmingSignOut
				) {
					Button(role: .destructive) {
						accountManager.clear()
					} label: {
						Text("Sign Out", comment: "Account Settings: button in alert to confirm signing out of all accounts")
					}
				}
				
				Toggle(isOn: $accountManager.shouldReauthAutomatically) {
					VStack(alignment: .leading, spacing: 4) {
						Text("Automatically Sign Back In", comment: "Settings: toggle")
						Text("This makes Recon Bolt automatically use your username & password to sign in again if you get signed out. If you have 2-factor authentication enabled, this may fail if it requires a new code, but it still works sometimes.", comment: "Settings: toggle description")
							.font(.footnote)
							.foregroundStyle(.secondary)
					}
				}
			} header: {
				Text("Management", comment: "Settings: section")
			}
		}
	}
	
	@ViewBuilder
	var cells: some View {
		if accountManager.storedAccounts.isEmpty {
			Text("Not signed in yet.", comment: "Account Settings")
			
			Button {
				loginTarget = .firstAccount
			} label: {
				Text("Sign In", comment: "Account Settings: button")
			}
			.font(.body.weight(.medium))
		} else {
			ForEach(accountManager.storedAccounts, id: \.self) { accountID in
				AccountCell(accountID: accountID, accountManager: accountManager)
			}
			.onDelete { accountManager.removeAccounts(at: $0) }
			.onMove { accountManager.storedAccounts.move(fromOffsets: $0, toOffset: $1) }
			.moveDisabled(!ownsProVersion)
			
			Button {
				loginTarget = .extraAccount
			} label: {
				HStack {
					Label {
						Text("Add another Account", comment: "Account Settings")
					} icon: {
						// the icon doesn't get tinted correctly if i don't do this…
						Image(systemName: "plus")
							.foregroundColor(ownsProVersion ? nil : .primary.opacity(0.25))
					}
					
					Spacer()
					
					if !ownsProVersion {
						ProExclusiveBadge()
					}
				}
			}
			.disabled(!ownsProVersion)
		}
	}
	
	var legalBoilerplate: some View {
		Text(verbatim: "Recon Bolt is not endorsed by Riot Games and does not reflect the views or opinions of Riot Games or anyone officially involved in producing or managing Riot Games properties. Riot Games and all associated properties are trademarks or registered trademarks of Riot Games, Inc.") // legally best not to translate this ig, couldn't find versions in other languages
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
						UserLabel(userID: accountID)
							.tint(.primary)
					} icon: {
						Image(systemName: "checkmark")
							.opacity(isActive ? 1 : 0)
					}
				}
				.disabled(!ownsProVersion && !isActive && (index ?? 0) > 0)
				
				Spacer()
			}
			.alert(Text("Could Not Load Account!"), for: $loadError)
			.deleteDisabled(isActive)
		}
	}
}

struct ProExclusiveBadge: View {
	var body: some View {
		Text("Pro", comment: "Badge applied to buttons that are exclusive to Pro, e.g. in the account settings")
			.font(.callout.smallCaps())
			.padding(.horizontal, 4)
			.offset(y: -1) // visually center the small caps
			.foregroundColor(.white)
			.blendMode(.destinationOut)
			.background(RoundedRectangle(cornerRadius: 4, style: .continuous))
			.compositingGroup()
	}
}

#if DEBUG
struct AccountSettingsView_Previews: PreviewProvider {
	static var previews: some View {
		List { AccountSettingsView(accountManager: .mocked) }
			.withToolbar()
		List { AccountSettingsView(accountManager: .mockEmpty) }
			.withToolbar()
	}
}
#endif
