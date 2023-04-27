import SwiftUI
import SwiftUIMissingPieces
import ValorantAPI

struct LoginForm: View {
	@ObservedObject var accountManager: AccountManager
	@State var isSigningIn = false
	
	@State var credentials = Credentials()
	
	@FocusState private var isPasswordFieldFocused
	
	@Environment(\.loadWithErrorAlerts) private var load
	@Environment(\.dismiss) private var dismiss
	
	var body: some View {
		ScrollView {
			ZStack {
				ProgressView {
					Text("signing in…", comment: "Login Form")
				}
				.opacity(isSigningIn ? 1 : 0)
				
				VStack(spacing: 20) {
					VStack(spacing: 12) {
						VStack {
							TextField(text: $credentials.username) {
								Text("Username", comment: "Login Form")
							}
							.textContentType(.username)
							.submitLabel(.next)
							.onSubmit { isPasswordFieldFocused = true }
							
							SecureField(text: $credentials.password) {
								Text("Password", comment: "Login Form")
							}
							.textContentType(.password)
							.submitLabel(.go)
							.onSubmit {
								isPasswordFieldFocused = false
								Task { await logIn() }
							}
							.focused($isPasswordFieldFocused)
						}
						.autocorrectionDisabled()
						.textInputAutocapitalization(.never)
						.frame(maxWidth: 240)
						
						if credentials.username.contains("#") {
							VStack(alignment: .leading, spacing: 8) {
								Text("""
									Looks like you're trying to enter your Riot ID (and tagline) as username! Your username is actually something else: it's what you use to sign into the Valorant launcher.

									If you don't know your username or don't have one, you can fix that at [account.riotgames.com](https://account.riotgames.com).
									""", comment: "Login Form"
								)
							}
							.font(.callout)
							.foregroundStyle(.secondary)
							.frame(maxWidth: .infinity)
						}
						
						AsyncButton(action: logIn) {
							Text("Sign In", comment: "Login Form: button")
								.bold()
						}
						.buttonStyle(.borderedProminent)
						.disabled(credentials.username.isEmpty || credentials.password.isEmpty)
					}
					
					VStack(spacing: 1) {
						trustInfo
						linkedAccountInfo
					}
					.compositingGroup()
					.cornerRadius(20)
				}
				.frame(idealWidth: 180)
				.textFieldStyle(.pretty)
				.opacity(isSigningIn ? 0.25 : 1)
				.blur(radius: isSigningIn ? 4 : 0)
				.disabled(isSigningIn)
				.buttonStyle(.bordered)
				.buttonBorderShape(.capsule)
				.padding()
			}
		}
		.sheet(caching: $accountManager.multifactorPrompt) {
			MultifactorPromptView(prompt: $0)
		} onDismiss: {
			$0.completion(.failure(AccountManager.MultifactorPromptError.cancelled))
		}
		.navigationTitle(Text("Sign In with your Riot account", comment: "Login Form"))
		.navigationBarTitleDisplayMode(.inline)
		.toolbar {
			ToolbarItemGroup(placement: .cancellationAction) {
				Button { dismiss() } label: {
					Text("Cancel")
				}
			}
		}
		.withToolbar(allowLargeTitles: false)
		.buttonBorderShape(.capsule)
	}
	
	var trustInfo: some View {
		FreeStandingDisclosureGroup {
			Text("I won't sugarcoat things. Due to the way this app uses the API, I believe there's no other way to sign in than to have people enter their credentials directly. Under those circumstances, there's really no good way for anyone to be sure their credentials remain safe. For what it's worth:", comment: "Login Form: is this safe?")
			
			let lines: [Text] = [
				Text("Your credentials only ever leave your device in the form of a login request directly to Riot. They are never stored or sent anywhere else.", comment: "Login Form: is this safe?"),
				Text("You can enable 2-factor authentication, so you'd at least have another layer of security if it went bad.", comment: "Login Form: is this safe?"),
				Text("The code is open-source and visible on GitHub; you can build it yourself if you want to be sure of what's running.", comment: "Login Form: is this safe?"),
			]
			ForEach(lines.indices, id: \.self) { index in
				HStack(alignment: .firstTextBaseline) {
					Text("•")
					lines[index]
				}
			}
			
			Text("TL;DR: you'll have to take my word for it, but Riot doesn't seem to mind.", comment: "Login Form: is this safe?")
				.fontWeight(.medium)
		} label: {
			Image(systemName: "lock")
				.frame(width: 24)
			Text("Is this safe?", comment: "Login Form: button/header")
		}
	}
	
	var linkedAccountInfo: some View {
		FreeStandingDisclosureGroup {
			Text("""
				Unfortunately, due to technical limitations, you cannot sign into Recon Bolt via your Google account, Apple ID, or anything but a Riot account.

				Assuming you signed up for Valorant using Google/Apple/etc., you can set up your account to add a username & password on Riot's site at [account.riotgames.com](https://account.riotgames.com). Note that your Riot ID is **not** the same as your username! If you've forgotten your username, you can reset it at [recovery.riotgames.com](https://recovery.riotgames.com).

				On that site, navigate to **Riot Account Sign-in** and set yourself a username and password. When you're done, you can use those same credentials to sign in above! Your social account will stay linked and you'll remain able to sign in with that on PC :)
				""", comment: "Login Form: sign in with google/apple/etc."
			)
		} label: {
			Image(systemName: "link")
				.frame(width: 24)
			Text("Sign in with Google/Apple/etc.", comment: "Login Form: button/header")
		}
	}
	
	@MainActor
	func logIn() async {
		isSigningIn = true
		defer { isSigningIn = false }
		
		await load(errorTitle: Text("Could not sign in!", comment: "Login Form: error title")) {
			do {
				try await accountManager.addAccount(using: credentials)
				dismiss()
			} catch AccountManager.MultifactorPromptError.cancelled {}
		}
	}
}

// can't make this a DisclosureGroupStyle because that was only introduced in iOS 16…
private struct FreeStandingDisclosureGroup<Content: View, Label: View>: View {
	@ViewBuilder var content: Content
	@ViewBuilder var label: Label
	
	@State var isExpanded = false
	
	var body: some View {
		VStack(spacing: 1) {
			Button {
				withAnimation {
					isExpanded.toggle()
				}
			} label: {
				HStack {
					label
						.foregroundColor(.primary)
					Spacer()
					Image(systemName: "chevron.down")
						.rotationEffect(.degrees(isExpanded ? 0 : -90))
				}
				.font(.headline.weight(.semibold))
				.padding()
			}
			.buttonStyle(.borderless)
			.background(Color.tertiaryGroupedBackground)
			
			if isExpanded {
				VStack(alignment: .leading, spacing: 12) {
					content
				}
				.frame(maxWidth: .infinity, alignment: .leading)
				.padding()
				.background(Color.tertiaryGroupedBackground)
			}
		}
	}
}

#if DEBUG
struct LoginSheet_Previews: PreviewProvider {
	static var previews: some View {
		Group {
			LoginForm(accountManager: .mocked)
			LoginForm(accountManager: .mocked, credentials: .init(username: "Game Name #Tag"))
			
			LoginForm(accountManager: .mocked, isSigningIn: true)
		}
		.withLoadErrorAlerts()
		.previewLayout(.sizeThatFits)
	}
}
#endif
