import SwiftUI
import SwiftUIMissingPieces
import HandyOperators

extension View {
	func withLoadErrorAlerts() -> some View {
		modifier(LoadWrapper())
	}
}

private struct LoadWrapper: ViewModifier {
	@State private var loadError: Error?
	@State private var errorTitle: Text?
	
	func body(content: Content) -> some View {
		content
			.environment(\.loadWithErrorAlerts, .init(closure: runTask))
			.alert(
				errorTitle ?? Text(""), // should never happen, but can't force unwrap here, and can't set title based on presented value directly
				for: $loadError
			)
	}
	
	func runTask(errorTitle: Text, _ task: () async throws -> Void) async {
		do {
			try await task()
		} catch is CancellationError {
			// ignore cancellation
		} catch let urlError as URLError where urlError.code == .cancelled {
			// ignore this type of cancellation too
		} catch {
			guard !Task.isCancelled else { return }
			print("error running load task:")
			dump(error)
			self.errorTitle = errorTitle
			loadError = error
		}
	}
}

extension View {
	func alert(_ title: LocalizedStringKey, for error: Binding<Error?>) -> some View {
		alert(Text(title), for: error)
	}
	
	func alert(_ title: Text, for error: Binding<Error?>) -> some View {
		alert(
			title,
			isPresented: error.isSome(),
			presenting: error.wrappedValue
		) { error in
			Button("Copy Error Details") {
				UIPasteboard.general.string = error.localizedDescription
			}
			Button("OK", role: .cancel) {}
		} message: { error in
			Text(error.localizedDescription)
		}
	}
}

extension EnvironmentValues {
	/// Executes some remote loading operation, handling any errors by displaying a dismissable alert.
	var loadWithErrorAlerts: LoadWithErrorAlerts {
		get { self[Key.self] }
		set { self[Key.self] = newValue }
	}
	
	private enum Key: EnvironmentKey {
		static let defaultValue: LoadWithErrorAlerts = .init { _, _ in
			guard !isInSwiftUIPreview else { return }
			fatalError("no load function provided in environment!")
		}
	}
}

struct LoadWithErrorAlerts {
	typealias LoadTask = () async throws -> Void
	
	fileprivate var closure: (Text, @escaping LoadTask) async -> Void
	
	public func callAsFunction(task: @escaping LoadTask) async {
		await closure(Text("An Error Occurred!", comment: "Default Error Alert Title"), task)
	}
	
	public func callAsFunction(errorTitle: LocalizedStringKey, task: @escaping LoadTask) async {
		await closure(Text(errorTitle), task)
	}
	
	public func callAsFunction(errorTitle: Text, task: @escaping LoadTask) async {
		await closure(errorTitle, task)
	}
}

extension LocalizedStringKey: @unchecked Sendable {} // trust me bro, it's fine

private struct PresentedError: Identifiable {
	let id = UUID()
	
	let error: Error
	
	init(_ error: Error) {
		self.error = error
	}
}
