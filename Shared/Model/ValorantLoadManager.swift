import SwiftUI
import ValorantAPI

extension View {
	func withValorantLoadFunction(manager: AccountManager) -> some View {
		modifier(ValorantLoadModifier(manager: manager))
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
	@ObservedObject var manager: AccountManager
	
	@Environment(\.loadWithErrorAlerts) private var load
	
	func body(content: Content) -> some View {
		content.environment(\.valorantLoad, load)
	}
	
	func load(_ task: @escaping (ValorantClient) async throws -> Void) async {
		guard let account = manager.activeAccount else { return }
		guard !Task.isCancelled else { return }
		
		await load {
			typealias APIError = ValorantClient.APIError
			
			do {
				try await task(account.client)
			} catch {
				guard !Task.isCancelled else { return }
				throw error
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
	
	private enum Key: EnvironmentKey {
		static let defaultValue: (@escaping ValorantLoadTask) async -> Void = { _ in
			guard !isInSwiftUIPreview else { return }
			fatalError("no valorant load function provided in environment!")
		}
	}
}
