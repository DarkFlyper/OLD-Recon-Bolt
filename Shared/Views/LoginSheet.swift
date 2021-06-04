import SwiftUI
import SwiftUIMissingPieces
import Combine
import ValorantAPI

struct LoginSheet: View {
	@Binding var data: ClientData?
	@State private(set) var credentials: Credentials
	
	@EnvironmentObject private var loadManager: LoadManager
	
	var body: some View {
		ZStack {
			ProgressView("logging in…")
				.opacity(loadManager.isLoading ? 1 : 0)
			VStack(spacing: 12) {
				Text("Log in with your Riot account")
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
				
				#if os(iOS)
				Button(action: logIn) {
					Text("Log In")
						.bold()
				}
				#endif
			}
			.frame(idealWidth: 180)
			.textFieldStyle(PrettyTextFieldStyle())
			.opacity(loadManager.isLoading ? 0.25 : 1)
		}
		.withoutSheetBottomPadding()
		.padding()
		.toolbar {
			ToolbarItemGroup(placement: .confirmationAction) {
				Button("Log In", action: logIn)
			}
		}
		.loadErrorTitle("Could not log in!")
	}
	
	func logIn() {
		loadManager.runTask(StandardClientData.authenticated(using: credentials)) { data = $0 }
	}
}

#if DEBUG
struct LoginSheet_Previews: PreviewProvider {
	static var previews: some View {
		LoginSheet(data: .constant(nil), credentials: .init())
			.withLoadManager()
			.inEachColorScheme()
			.previewLayout(.sizeThatFits)
	}
}
#endif
