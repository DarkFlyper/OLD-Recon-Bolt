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
	@State private var errorTitle: LocalizedStringKey?
	
	func body(content: Content) -> some View {
		content
			.environment(\.loadWithErrorAlerts, runTask)
			.alert(errorTitle ?? "An Error Occurred!", for: $loadError)
	}
	
	func runTask(errorTitle: LocalizedStringKey? = nil, _ task: () async throws -> Void) async {
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
	typealias LoadTask = () async throws -> Void
	
	/// Executes some remote loading operation, handling any errors by displaying a dismissable alert.
	var loadWithErrorAlerts: (LocalizedStringKey?, @escaping LoadTask) async -> Void {
		get { self[Key.self] }
		set { self[Key.self] = newValue }
	}
	
	private enum Key: EnvironmentKey {
		static let defaultValue: (LocalizedStringKey?, @escaping LoadTask) async -> Void = { _, _ in
			guard !isInSwiftUIPreview else { return }
			fatalError("no load function provided in environment!")
		}
	}
}

private struct PresentedError: Identifiable {
	let id = UUID()
	
	let error: Error
	
	init(_ error: Error) {
		self.error = error
	}
}
