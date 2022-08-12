import SwiftUI
import SwiftUIMissingPieces
import ValorantAPI

struct LoginForm: View {
	@Binding var data: ClientData?
	@State private(set) var credentials: Credentials
	@State var isSigningIn = false
	@FocusState private var isPasswordFieldFocused
	var keychain: Keychain
	
	@State var multifactorPrompt: MultifactorPrompt? {
		didSet { isPromptingMultifactor = multifactorPrompt != nil }
	}
	@State var isPromptingMultifactor = false
	
	@Environment(\.loadWithErrorAlerts) private var load
	
	var body: some View {
		ZStack {
			ProgressView("signing in…")
				.opacity(isSigningIn ? 1 : 0)
			
			VStack(spacing: 12) {
				Text("Sign in with your Riot account")
					.font(.title2.weight(.medium))
					.multilineTextAlignment(.center)
					.lineLimit(2)
					.fixedSize(horizontal: false, vertical: true) // without this the line limit doesn't seem to work
				
				regionSelection
				
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
				
				trustInfo
			}
			.frame(idealWidth: 180)
			.textFieldStyle(.pretty)
			.opacity(isSigningIn ? 0.25 : 1)
			.blur(radius: isSigningIn ? 4 : 0)
		}
		.buttonStyle(.bordered)
		.buttonBorderShape(.capsule)
		.padding()
		.loadErrorAlertTitle("Could not sign in!")
		.sheet(
			isPresented: $isPromptingMultifactor,
			onDismiss: {
				multifactorPrompt?.completion(
					.failure(MultifactorPrompt.PromptError.cancelled)
				)
			},
			content: {
				MultifactorPromptView(prompt: multifactorPrompt!)
			}
		)
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
			.background(Color(.tertiarySystemGroupedBackground))
			
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
				.padding(12)
				.background(Color(.tertiarySystemGroupedBackground))
			}
		}
		.compositingGroup()
		.cornerRadius(20)
	}
	
	@ScaledMetric(relativeTo: .body) private var pickerHeight = 34
	
	@ViewBuilder
	var regionSelection: some View {
		Menu {
			ForEach(Location.all) { location in
				Button {
					credentials.location = location
				} label: {
					HStack {
						Text(location.name)
						
						if credentials.location == location {
							Image(systemName: "checkmark")
						}
					}
				}
			}
		} label: {
			HStack(spacing: 1) {
				Text(credentials.location.name)
					.padding(.leading, 12) // extra leading padding for capsule
					.padding(.trailing, 8)
					.frame(maxHeight: .infinity)
					.background(.accentColor.opacity(0.2))
				
				Image(systemName: "chevron.down")
					.padding(.leading, 6)
					.padding(.trailing, 8)
					.foregroundColor(.white)
					.frame(maxHeight: .infinity)
					.background(.accentColor)
			}
			.frame(height: pickerHeight)
			.fixedSize()
			.clipShape(Capsule())
		}
		.menuStyle(.borderlessButton)
	}
	
	@MainActor
	func logIn() async {
		isSigningIn = true
		
		await load {
			do {
				data = try await StandardClientData.authenticated(
					using: credentials,
					multifactorHandler: handleMultifactor
				)
				credentials.save(to: keychain)
			} catch MultifactorPrompt.PromptError.cancelled {}
		}
		
		isSigningIn = false
	}
	
	@MainActor
	func handleMultifactor(info: MultifactorInfo) async throws -> String {
		let code = try await withCheckedThrowingContinuation {
			multifactorPrompt = .init(info: info, completion: $0.resume(with:))
		}
		multifactorPrompt = nil
		return code
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
