import SwiftUI
import ValorantAPI

extension View {
	func withValorantLoadFunction(dataStore: ClientDataStore) -> some View {
		modifier(ValorantLoadModifier(dataStore: dataStore))
	}
	
	func valorantLoadTask(_ loadTask: @escaping ValorantLoadTask) -> some View {
		modifier(ValorantLoadTaskModifier(loadTask: loadTask))
	}
	
	func valorantLoadTask<T>(id: T, _ loadTask: @escaping ValorantLoadTask) -> some View where T: Equatable {
		modifier(ValorantLoadTaskWithIDModifier(id: id, loadTask: loadTask))
	}
}

private struct ValorantLoadTaskModifier: ViewModifier {
	let loadTask: ValorantLoadTask
	
	@Environment(\.valorantLoad) private var load
	
	func body(content: Content) -> some View {
		content.task { await load(loadTask) }
	}
}

private struct ValorantLoadTaskWithIDModifier<ID: Equatable>: ViewModifier {
	let id: ID
	let loadTask: ValorantLoadTask
	
	@Environment(\.valorantLoad) private var load
	
	func body(content: Content) -> some View {
		content.task(id: id) { await load(loadTask) }
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
	
	@Sendable
	func updateClientVersion() async {
		guard let version = assets?.version.riotClientVersion else { return }
		await dataStore.data?.client.setClientVersion(version)
	}
	
	func load(_ task: @escaping (ValorantClient) async throws -> Void) async {
		guard let data = dataStore.data else { return }
		guard !Task.isCancelled else { return }
		
		await load {
			typealias APIError = ValorantClient.APIError
			
			do {
				guard !Task.isCancelled else { return }
				try await task(data.client)
			} catch let error as APIError where error.recommendsReauthentication {
				print("reauthenticating!")
				let reauthenticated = try await data.reauthenticated()
				dataStore.data = reauthenticated
				await updateClientVersion()
				try await task(reauthenticated.client) // don't recurse infinitely
			}
		}
	}
}

typealias ValorantLoadTask = (ValorantClient) async throws -> Void

extension EnvironmentValues {
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
