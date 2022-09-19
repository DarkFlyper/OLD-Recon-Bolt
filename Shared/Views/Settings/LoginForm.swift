import SwiftUI
import SwiftUIMissingPieces
import ValorantAPI

struct LoginForm: View {
	@Binding var data: ClientData?
	@State private(set) var credentials: Credentials
	@State var isSigningIn = false
	@FocusState private var isPasswordFieldFocused
	var keychain: Keychain
	
	@State var multifactorPrompt: MultifactorPrompt?
	
	@Environment(\.loadWithErrorAlerts) private var load
	@Environment(\.dismiss) private var dismiss
	
	var body: some View {
		ScrollView {
			ZStack {
				ProgressView("signing in…")
					.opacity(isSigningIn ? 1 : 0)
				
				VStack(spacing: 20) {
					VStack(spacing: 12) {
						VStack {
							TextField("Username", text: $credentials.username)
								.autocapitalization(.none)
								.submitLabel(.next)
								.onSubmit { isPasswordFieldFocused = true }
							
							SecureField("Password", text: $credentials.password)
								.submitLabel(.go)
								.onSubmit {
									isPasswordFieldFocused = false
									Task { await logIn() }
								}
								.focused($isPasswordFieldFocused)
						}
						.frame(maxWidth: 240)
						
						AsyncButton(action: logIn) {
							Text("Sign In")
								.bold()
						}
						.buttonStyle(.borderedProminent)
					}
					
					trustInfo
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
		.loadErrorAlertTitle("Could not sign in!")
		.navigationTitle("Sign In with your Riot account")
		.navigationBarTitleDisplayMode(.inline)
		.toolbar {
			ToolbarItemGroup(placement: .cancellationAction) {
				Button { dismiss() } label: {
					Text("Cancel")
				}
			}
		}
		.sheet(caching: $multifactorPrompt) {
			MultifactorPromptView(prompt: $0)
		} onDismiss: {
			$0.completion(.failure(PromptError.cancelled))
		}
		.withToolbar(allowLargeTitles: false)
	}
	
	@State private var isTrustInfoExpanded = false
	
	var trustInfo: some View {
		VStack(spacing: 1) {
			Button {
				withAnimation {
					isTrustInfoExpanded.toggle()
				}
			} label: {
				HStack {
					Image(systemName: "lock")
						.foregroundColor(.primary)
					Text("Is this safe?")
						.foregroundColor(.primary)
					Spacer()
					Image(systemName: "chevron.down")
						.rotationEffect(.degrees(isTrustInfoExpanded ? 0 : -90))
				}
				.font(.headline.weight(.semibold))
				.padding()
			}
			.buttonStyle(.borderless)
			.background(Color.tertiaryGroupedBackground)
			
			if isTrustInfoExpanded {
				VStack(alignment: .leading, spacing: 8) {
					Text("I won't sugarcoat things. Due to the way this app uses the API, I believe there's no other way to sign in than to have people enter their credentials directly. Under those circumstances, there's really no good way for anyone to be sure their credentials remain safe. For what it's worth:")
					
					let lines: [LocalizedStringKey] = [
						"Your credentials only ever leave your device in the form of a login request directly to Riot. They are never stored or sent anywhere else.",
						"You can enable 2-factor authentication, so you'd at least have another layer of security if it went bad.",
						"The code is open-source and visible on GitHub; you can build it yourself if you want to be sure of what's running.",
					]
					ForEach(lines.indices, id: \.self) { index in
						HStack(alignment: .firstTextBaseline) {
							Text("•")
							Text(lines[index])
						}
					}
					
					Text("TL;DR: you'll have to take my word for it.")
						.fontWeight(.medium)
				}
				.frame(maxWidth: .infinity, alignment: .leading)
				.padding()
				.background(Color.tertiaryGroupedBackground)
			}
		}
		.compositingGroup()
		.cornerRadius(20)
	}
	
	@MainActor
	func logIn() async {
		isSigningIn = true
		defer { isSigningIn = false }
		
		await load {
			do {
				data = try await StandardClientData.authenticated(
					using: credentials,
					multifactorHandler: handleMultifactor
				)
				credentials.save(to: keychain)
				dismiss()
			} catch PromptError.cancelled {}
		}
	}
	
	@MainActor
	func handleMultifactor(info: MultifactorInfo) async throws -> String {
		defer { multifactorPrompt = nil }
		let code = try await withRobustThrowingContinuation {
			multifactorPrompt = .init(info: info, completion: $0)
		}
		return code
	}
	
	enum PromptError: Error {
		case cancelled
	}
}

#if DEBUG
struct LoginSheet_Previews: PreviewProvider {
	static var previews: some View {
		Group {
			LoginForm(data: .constant(nil), credentials: .init(), keychain: MockKeychain())
			
			LoginForm(data: .constant(nil), credentials: .init(), isSigningIn: true, keychain: MockKeychain())
		}
		.withLoadErrorAlerts()
		.previewLayout(.sizeThatFits)
	}
}
#endif
