import SwiftUI
import ValorantAPI

final class ValorantLoadManager: LoadManager {
	private typealias APIError = ValorantClient.APIError
	private let dataStore: ClientDataStore
	
	var canLoad: Bool {
		dataStore.data != nil
	}
	
	init(dataStore: ClientDataStore, clientVersion: String? = nil) {
		if let version = clientVersion {
			dataStore.data?.client.setClientVersion(version)
		}
		self.dataStore = dataStore
	}
	
	func loadAsync(
		_ task: @escaping (ValorantClient) async throws -> Void
	) {
		async { await load(task) }
	}
	
	func load(
		_ task: @escaping (ValorantClient) async throws -> Void
	) async {
		guard let data = dataStore.data else { return }
		#if DEBUG
		guard !(data is MockClientData) else { return }
		#endif
		
		await runTask {
			do {
				try await task(data.client)
			} catch APIError.tokenFailure, APIError.unauthorized {
				dataStore.data = try await data.reauthenticated()
				try await task(data.client)
			}
		}
	}
}
