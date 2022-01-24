import SwiftUI
import SwiftUIMissingPieces
import ValorantAPI

struct LoginForm: View {
	@Binding var data: ClientData?
	@State private(set) var credentials: Credentials
	@State var isSigningIn = false
	@FocusState private var isPasswordFieldFocused
	
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
				
#if !os(macOS)
				AsyncButton(action: logIn) {
					Text("Sign In")
						.bold()
				}
				.buttonStyle(.borderedProminent)
#endif
			}
			.frame(idealWidth: 180)
			.textFieldStyle(PrettyTextFieldStyle())
			.opacity(isSigningIn ? 0.25 : 1)
			.blur(radius: isSigningIn ? 4 : 0)
		}
		.buttonStyle(.bordered)
		.buttonBorderShape(.capsule)
		.withoutSheetBottomPadding()
		.padding()
#if os(macOS)
		.toolbar {
			ToolbarItemGroup(placement: .confirmationAction) {
				Button("Sign In", action: logIn)
			}
		}
#endif
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
	
	@ScaledMetric(relativeTo: .body) private var pickerHeight = 34
	
	var regionSelection: some View {
		VStack {
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
		}
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
			LoginForm(data: .constant(nil), credentials: .init())
			
			LoginForm(data: .constant(nil), credentials: .init(), isSigningIn: true)
		}
		.withLoadErrorAlerts()
		.inEachColorScheme()
		.previewLayout(.sizeThatFits)
	}
}
#endif
