import SwiftUI
import SwiftUIMissingPieces
import Combine

struct LoginSheet: View {
	@ObservedObject private var credentials = CredentialsStorage()
	@State private var loginRequest: AnyCancellable?
	@Binding var client: Client?
	@State private var loginError: PresentedError?
	@State private var isLoading = false
	
	var body: some View {
		ZStack {
			ProgressView("logging in…")
				.opacity(isLoading ? 1 : 0)
			VStack(spacing: 12) {
				Text("Log in with your Riot account")
					.font(.title2)
					.multilineTextAlignment(.center)
					.lineLimit(2)
					.fixedSize(horizontal: false, vertical: true) // without this the line limit doesn't seem to work
				VStack {
					TextField("Username", text: $credentials.username)
					SecureField("Password", text: $credentials.password) { logIn() }
				}
				.frame(maxWidth: 180)
				
				#if os(iOS)
				Button(action: logIn, label: {
					Text("Log In")
						.bold()
				})
				#endif
			}
			.frame(idealWidth: 180)
			.textFieldStyle(PrettyTextFieldStyle())
			.opacity(isLoading ? 0.25 : 1)
		}
		.withoutSheetBottomPadding()
		.padding()
		.toolbar {
			ToolbarItemGroup(placement: .confirmationAction) {
				Button("Log In", action: logIn)
			}
		}
		.alert(item: $loginError) { error in
			Alert(
				title: Text("Could not log in!"),
				message: Text(error.error.localizedDescription),
				dismissButton: .default(Text("OK"))
			)
		}
	}
	
	func logIn() {
		isLoading = true
		loginRequest = Client
			.authenticated(username: credentials.username, password: credentials.password)
			.receive(on: DispatchQueue.main)
			.sinkResult { client = $0 }
				onFailure: { loginError = .init($0) }
				always: { isLoading = false }
	}
}

struct LoginSheet_Previews: PreviewProvider {
	static var previews: some View {
		LoginSheet(client: .constant(nil)).preferredColorScheme(.light)
		LoginSheet(client: .constant(nil)).preferredColorScheme(.dark)
	}
}
