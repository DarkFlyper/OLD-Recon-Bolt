import SwiftUI

// TODO: put this in SwiftUIMissingPieces if it works

/// A ``NavigationLink`` that passes through certain environment values.
///
/// For your app, make a `typealias` to this with the ``KeyPaths`` type specified, e.g.:
/// ```
/// typealias TransparentNavigationLink<Destination: View, Label: View>
/// = BaseTransparentNavigationLink<ReconBoltKeyPathCollection, Destination, Label>
/// ```
struct BaseTransparentNavigationLink<
	KeyPaths: EnvironmentKeyPathCollection,
	Destination: View,
	Label: View
>: View {
	var isActive: Binding<Bool>?
	@ViewBuilder var destination: () -> Destination
	@ViewBuilder var label: () -> Label
	
	@Environment(\.self) private var environment
	
	var body: some View {
		let newDestination = {
			destination().transformEnvironment(\.self) { new in
				for keyPath in KeyPaths.copiedValues {
					keyPath.copyValue(to: &new, from: environment)
				}
			}
		}
		
		if let isActive {
			NavigationLink(isActive: isActive, destination: newDestination, label: label)
		} else {
			NavigationLink(destination: newDestination, label: label)
		}
	}
}

// TODO: convenience inits

protocol EnvironmentKeyPath {
	func copyValue(to new: inout EnvironmentValues, from existing: EnvironmentValues)
}

extension WritableKeyPath: EnvironmentKeyPath where Root == EnvironmentValues {
	func copyValue(to new: inout EnvironmentValues, from existing: EnvironmentValues) {
		new[keyPath: self] = existing[keyPath: self]
	}
}

protocol EnvironmentKeyPathCollection {
	static var copiedValues: [any EnvironmentKeyPath] { get }
}

// recon bolt specific stuff

enum ReconBoltKeyPathCollection: EnvironmentKeyPathCollection {
	static let copiedValues: [any EnvironmentKeyPath] = [
		\EnvironmentValues.anonymization,
		\EnvironmentValues.location,
	]
}

typealias TransparentNavigationLink<Destination: View, Label: View>
= BaseTransparentNavigationLink<ReconBoltKeyPathCollection, Destination, Label>
