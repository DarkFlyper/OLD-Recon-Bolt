import SwiftUI
import SwiftUIMissingPieces
import Combine
import ValorantAPI

struct LoginForm: View {
	@Binding var data: ClientData?
	@State private(set) var credentials: Credentials
	
	@EnvironmentObject private var loadManager: LoadManager
	
	var body: some View {
		ZStack {
			ProgressView("signing in…")
				.opacity(loadManager.isLoading ? 1 : 0)
			
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
					SecureField("Password", text: $credentials.password) { logIn() }
				}
				.frame(maxWidth: 180)
				
				#if !os(macOS)
				Button(action: logIn) {
					Text("Sign In")
						.bold()
				}
				#endif
			}
			.frame(idealWidth: 180)
			.textFieldStyle(PrettyTextFieldStyle())
			.opacity(loadManager.isLoading ? 0.25 : 1)
			.blur(radius: loadManager.isLoading ? 4 : 0)
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
	
	func logIn() {
		loadManager.runTask(StandardClientData.authenticated(using: credentials)) { data = $0 }
	}
}

#if DEBUG
struct LoginSheet_Previews: PreviewProvider {
	static var previews: some View {
		Group {
			LoginForm(data: .constant(nil), credentials: .init())
				.withLoadManager()
			
			LoginForm(data: .constant(nil), credentials: .init())
				.withLoadManager(LoadManager.mockLoading)
		}
		.inEachColorScheme()
		.previewLayout(.sizeThatFits)
	}
}
#endif
