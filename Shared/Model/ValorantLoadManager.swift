import SwiftUI
import Combine
import ValorantAPI

final class ValorantLoadManager: LoadManager {
	private let dataStore: ClientDataStore
	
	var canLoad: Bool {
		!isLoading && dataStore.data != nil
	}
	
	init(dataStore: ClientDataStore) {
		self.dataStore = dataStore
	}
	
	func load<P: Publisher>(
		_ task: @escaping (ValorantClient) -> P,
		onSuccess: @escaping (P.Output) -> Void
	) {
		guard let data = dataStore.data else { return }
		#if DEBUG
		guard !(data is MockClientData) else { return }
		#endif
		runTask(
			task(data.client).tryCatch { error -> AnyPublisher<P.Output, Error> in
				switch error {
				case ValorantClient.APIError.tokenFailure as Error,
					 ValorantClient.APIError.unauthorized as Error:
					return data.reauthenticated()
						.receive(on: DispatchQueue.main)
						.also { self.dataStore.data = $0 }
						.flatMap { task($0.client).mapError { $0 } }
						.eraseToAnyPublisher()
				default:
					throw error
				}
			},
			onSuccess: onSuccess
		)
	}
	
	func loadButton(
		_ title: String,
		dispatchTask: @escaping (ValorantLoadManager) -> Void
	) -> some View {
		Button(title) {
			dispatchTask(self)
		}
		.disabled(!canLoad)
		.buttonStyle(UnifiedLinkButtonStyle())
	}
}
