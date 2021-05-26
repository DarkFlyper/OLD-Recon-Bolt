import SwiftUI
import SwiftUIMissingPieces
import Combine
import ValorantAPI
import UserDefault

final class LoadManager: ObservableObject {
	@UserDefault("LoadManager.client")
	private static var storedClient: ValorantClient?
	
	@Published var client: ValorantClient? = LoadManager.storedClient {
		didSet { Self.storedClient = client }
	}
	@Published private var loadTask: AnyCancellable?
	@Published fileprivate var loadError: PresentedError?
	
	fileprivate let credentials: CredentialsStorage
	
	init(credentials: CredentialsStorage) {
		self.credentials = credentials
	}
	
	var canLoad: Bool {
		!isLoading && client != nil
	}
	
	var isLoading: Bool {
		loadTask != nil
	}
	
	func load<P: Publisher>(
		_ task: @escaping (ValorantClient) -> P,
		onSuccess: @escaping (P.Output) -> Void
	) {
		guard let client = client else { return }
		runTask(
			task(client).tryCatch { [credentials] error -> AnyPublisher<P.Output, Error> in
				switch error {
				case ValorantClient.APIError.tokenFailure as Error,
					 ValorantClient.APIError.unauthorized as Error:
					return ValorantClient.authenticated(
						username: credentials.username,
						password: credentials.password,
						region: credentials.region
					)
					.receive(on: DispatchQueue.main)
					.also { self.client = $0 }
					.flatMap { task($0).mapError { $0 } }
					.eraseToAnyPublisher()
				default:
					throw error
				}
			},
			onSuccess: onSuccess
		)
	}
	
	func runTask<P: Publisher>(
		_ task: P,
		onSuccess: @escaping (P.Output) -> Void
	) {
		loadTask = task
			.receive(on: DispatchQueue.main)
			.sinkResult(
				onSuccess: onSuccess,
				onFailure: { self.loadError = .init($0) },
				always: { self.loadTask = nil }
			)
	}
	
	func loadButton(
		_ title: String,
		dispatchTask: @escaping (LoadManager) -> Void
	) -> some View {
		Button(title) {
			dispatchTask(self)
		}
		.disabled(!canLoad)
		.buttonStyle(UnifiedLinkButtonStyle())
	}
}

extension ValorantClient: DefaultsValueConvertible {}

extension View {
	func withLoadManager() -> some View {
		LoadWrapper.EnvironmentAccessor { self }
	}
}

private struct LoadWrapper<Content: View>: View {
	@ViewBuilder let content: () -> Content
	@State private var errorTitle = "Error loading data!"
	@StateObject private var loadManager: LoadManager
	
	@EnvironmentObject private var credentials: CredentialsStorage
	
	init(credentials: CredentialsStorage, @ViewBuilder content: @escaping () -> Content) {
		self.content = content
		self._loadManager = .init(wrappedValue: LoadManager(credentials: credentials)) // dw it's an autoclosure
	}
	
	var body: some View {
		content()
			.onPreferenceChange(LoadErrorTitleKey.self) {
				errorTitle = $0 ?? errorTitle
			}
			.environmentObject(loadManager)
			.alert(item: $loadManager.loadError) { error in
				Alert(
					title: Text(errorTitle),
					message: Text(verbatim: error.error.localizedDescription),
					dismissButton: .default(Text("OK"))
				)
			}
	}
	
	struct EnvironmentAccessor: View {
		@EnvironmentObject private var credentials: CredentialsStorage
		@ViewBuilder let content: () -> Content
		
		var body: some View {
			LoadWrapper(credentials: credentials, content: content)
		}
	}
}

private enum LoadErrorTitleMarker {}
private typealias LoadErrorTitleKey = SimplePreferenceKey<LoadErrorTitleMarker, String>

extension View {
	func loadErrorTitle(_ title: String) -> some View {
		preference(key: LoadErrorTitleKey.self, value: title)
	}
}

private struct PresentedError: Identifiable {
	let id = UUID()
	
	let error: Error
	
	init(_ error: Error) {
		self.error = error
	}
}
