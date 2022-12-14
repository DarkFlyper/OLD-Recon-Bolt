import SwiftUI
import Combine
import ValorantAPI

extension View {
	func withLocalData<Value: LocalDataStored>(
		_ value: LocalData<Value>,
		id: Value.ID,
		animation: Animation? = .default
	) -> some View {
		modifier(LocalDataModifier(value: value.$wrappedValue, id: id, animation: animation))
	}
	
	func withLocalData<Value: LocalDataAutoUpdatable>(
		_ value: LocalData<Value>,
		id: Value.ID,
		shouldAutoUpdate: Bool = false,
		animation: Animation? = .default
	) -> some View {
		modifier(LocalDataModifier(
			value: value.$wrappedValue,
			id: id,
			animation: animation,
			autoUpdate: shouldAutoUpdate ? Value.autoUpdate(for:using:) : nil
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

@propertyWrapper
struct LocalData<Value: LocalDataStored>: DynamicProperty {
	@State fileprivate(set) var wrappedValue: Value?
	
	var projectedValue: Self { self }
	
	init(wrappedValue: Value?) {
		self._wrappedValue = .init(initialValue: wrappedValue)
	}
}

private struct LocalDataModifier<Value: LocalDataStored>: ViewModifier {
	@Binding var value: Value?
	var id: Value.ID
	var animation: Animation?
	var autoUpdate: ((Value.ID, ValorantClient) async throws -> Void)? = nil
	
	@State private var token: (id: Value.ID, AnyCancellable)? = nil
	@Environment(\.isLocalDataLocked) var isLocalDataLocked
	@Environment(\.valorantLoad) var load
	
	func body(content: Content) -> some View {
		content
			.task(id: id) {
				guard !isLocalDataLocked else { return }
				if let token, token.id == id { return }
				let cancellable = LocalDataProvider.shared[keyPath: Value.managerPath]
					.objectPublisher(for: id)
					.receive(on: DispatchQueue.main)
					.sink { newValue, wasCached in
						withAnimation(wasCached ? nil : animation) {
							value = newValue
						}
					}
				token = (id, cancellable)
			}
			.valorantLoadTask(id: id) { await attemptAutoUpdate(client: $0) }
			.onSceneActivation {
				await load {
					await attemptAutoUpdate(client: $0)
				}
			}
	}
	
	func attemptAutoUpdate(client: ValorantClient) async {
		guard !isLocalDataLocked else { return }
		do {
			try await autoUpdate?(id, client)
		} catch {
			print("error auto-updating \(Value.self) \(id)!", error)
		}
	}
}
