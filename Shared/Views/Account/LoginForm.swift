import SwiftUI
import SwiftUIMissingPieces
import ValorantAPI

struct LoginForm: View {
	@Binding var data: ClientData?
	@State private(set) var credentials: Credentials
	@State var isSigningIn = false
	
	@EnvironmentObject private var loadManager: LoadManager
	
	var body: some View {
		ZStack {
			ProgressView("signing in…")
				.opacity(isSigningIn ? 1 : 0)
			
			VStack(spacing: 12) {
				Text("Sign in with your Riot account")
					.font(.title2)
					.multilineTextAlignment(.center)
					.lineLimit(2)
					.fixedSize(horizontal: false, vertical: true) // without this the line limit doesn't seem to work
				
				Picker("Region: \(credentials.region.name)", selection: $credentials.region) {
					ForEach(Region.allCases, id: \.rawValue) { region in
						Text(verbatim: region.name).tag(region)
					}
				}
				.pickerStyle(MenuPickerStyle())
				
				VStack {
					TextField("Username", text: $credentials.username)
					SecureField("Password", text: $credentials.password) {
						async { await logIn() }
					}
				}
				.frame(maxWidth: 180)
				
				#if !os(macOS)
				Button(role: nil, action: logIn) {
					Text("Sign In")
						.bold()
				}
				#endif
			}
			.frame(idealWidth: 180)
			.textFieldStyle(PrettyTextFieldStyle())
			.opacity(isSigningIn ? 0.25 : 1)
			.blur(radius: isSigningIn ? 4 : 0)
		}
		.withoutSheetBottomPadding()
		.padding()
		.toolbar {
			#if os(macOS)
			ToolbarItemGroup(placement: .confirmationAction) {
				Button("Sign In", action: logIn)
			}
			#endif
		}
		.loadErrorTitle("Could not sign in!")
	}
	
	func logIn() async {
		isSigningIn = true
		
		await loadManager.runTask {
			data = try await StandardClientData.authenticated(using: credentials)
		}
		
		isSigningIn = false
	}
}

#if DEBUG
struct LoginSheet_Previews: PreviewProvider {
	static var previews: some View {
		Group {
			LoginForm(data: .constant(nil), credentials: .init())
			
			LoginForm(data: .constant(nil), credentials: .init(), isSigningIn: true)
		}
		.withLoadManager()
		.inEachColorScheme()
		.previewLayout(.sizeThatFits)
	}
}
#endif
