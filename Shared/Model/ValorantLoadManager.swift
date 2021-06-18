import SwiftUI
import ValorantAPI

extension View {
	func withValorantLoadFunction(dataStore: ClientDataStore) -> some View {
		modifier(ValorantLoadModifier(dataStore: dataStore))
	}
}

private struct ValorantLoadModifier: ViewModifier {
	@ObservedObject var dataStore: ClientDataStore
	
	@Environment(\.loadWithErrorAlerts) private var load
	@Environment(\.assets) private var assets
	
	func body(content: Content) -> some View {
		content.environment(\.valorantLoad, load)
			.task(id: assets?.version.riotClientVersion, updateClientVersion)
			.task(id: dataStore.data?.client.id, updateClientVersion)
	}
	
	func updateClientVersion() {
		guard let version = assets?.version.riotClientVersion else { return }
		dataStore.data?.client.setClientVersion(version)
	}
	
	func load(_ task: @escaping (ValorantClient) async throws -> Void) async {
		guard let data = dataStore.data else { return }
		
		await load {
			typealias APIError = ValorantClient.APIError
			
			do {
				try await task(data.client)
			} catch APIError.tokenFailure, APIError.unauthorized {
				print("reauthenticating!")
				let reauthenticated = try await data.reauthenticated()
				dataStore.data = reauthenticated
				try await task(reauthenticated.client)
			}
		}
	}
}

extension EnvironmentValues {
	typealias ValorantLoadTask = (ValorantClient) async throws -> Void
	
	/// Executes some remote loading operation using the given ``ValorantClient``.
	var valorantLoad: (@escaping ValorantLoadTask) async -> Void {
		get { self[Key.self] }
		set { self[Key.self] = newValue }
	}
	
	private struct Key: EnvironmentKey {
		static let defaultValue: (@escaping ValorantLoadTask) async -> Void = { _ in
			guard !isInSwiftUIPreview else { return }
			fatalError("no valorant load function provided in environment!")
		}
	}
}
