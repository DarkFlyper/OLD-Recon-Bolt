import SwiftUI
import Combine
import ValorantAPI

extension View {
	@MainActor
	func withLocalData<Value: LocalDataStored>(
		_ value: LocalData<Value>,
		id: Value.ID,
		animation: Animation? = .default
	) -> some View {
		modifier(LocalDataModifier(value: value.$wrappedValue, id: id, animation: animation))
	}
	
	@MainActor
	func withLocalData<Value: LocalDataAutoUpdatable>(
		_ value: LocalData<Value>,
		id: Value.ID,
		shouldAutoUpdate: Bool = false,
		shouldReportErrors: Bool = false,
		animation: Animation? = .default
	) -> some View {
		modifier(LocalDataModifier(
			value: value.$wrappedValue,
			id: id,
			animation: animation,
			shouldReportErrors: shouldReportErrors,
			autoUpdate: !shouldAutoUpdate ? nil : { id, client in
				// wait a bit first in case this view disappears and cancels the task
				await Task.sleep(seconds: 0.1, tolerance: 0.01)
				try Task.checkCancellation()
				try await Value.autoUpdate(for: id, using: client)
			}
		))
	}
	
	func lockingLocalData() -> some View {
		self.environment(\.isLocalDataLocked, true)
	}
}

extension EnvironmentValues {
	var isLocalDataLocked: Bool {
		get { self[Key.self] }
		set { self[Key.self] = newValue }
	}
	
	private enum Key: EnvironmentKey {
		static let defaultValue = false
	}
}

@MainActor
@propertyWrapper
struct LocalData<Value: LocalDataStored>: DynamicProperty {
	@State fileprivate(set) var wrappedValue: Value?
	
	var projectedValue: Self { self }
	
	init() {}
	
	/// checks the cache even before the first body evaluation
	init(id: Value.ID?) {
		self._wrappedValue = .init(initialValue: id.flatMap {
			LocalDataProvider.shared[keyPath: Value.managerPath]
				.loadedObject(for: $0)
		})
	}
	
	#if DEBUG
	init(preview: Value) {
		self._wrappedValue = .init(initialValue: preview)
	}
	#endif
}

private struct LocalDataModifier<Value: LocalDataStored>: ViewModifier {
	@Binding var value: Value?
	var id: Value.ID
	var animation: Animation?
	var shouldReportErrors = false
	var autoUpdate: ((Value.ID, ValorantClient) async throws -> Void)? = nil
	
	@State private var tokenStorage = TokenStorage()
	@Environment(\.isLocalDataLocked) var isLocalDataLocked
	@Environment(\.valorantLoad) var load
	
	func body(content: Content) -> some View {
		content
			.task(id: id) {
				guard !isLocalDataLocked else { return }
				tokenStorage.ensureSubscribed(for: id) {
					LocalDataProvider.shared[keyPath: Value.managerPath]
						.objectPublisher(for: id)
						.receive(on: DispatchQueue.main)
						.sink { newValue, wasCached in
							withAnimation(wasCached ? nil : animation) {
								value = newValue
							}
						}
				}
			}
			.valorantLoadTask(id: id) { try await attemptAutoUpdate(client: $0) }
			.onSceneActivation {
				await load {
					try await attemptAutoUpdate(client: $0)
				}
			}
	}
	
	func attemptAutoUpdate(client: ValorantClient) async throws {
		guard !isLocalDataLocked else { return }
		do {
			try await autoUpdate?(id, client)
		} catch {
			print("error auto-updating \(Value.self) \(id)!", error)
			if shouldReportErrors {
				throw error
			}
		}
	}
	
	private final class TokenStorage {
		// not published—this shouldn't cause view updates
		var token: (id: Value.ID, AnyCancellable)? = nil
		
		func ensureSubscribed(for id: Value.ID, subscribe: () -> AnyCancellable) {
			if let token, token.id == id { return }
			token = (id, subscribe())
		}
	}
}
