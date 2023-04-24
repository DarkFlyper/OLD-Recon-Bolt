import Algorithms
import Foundation
import HandyOperators

extension Sequence {
	// why this isn't in the stdlib is beyond me (maybe an overload ambiguity issue leading to poor diagnostics?)
	func sorted<ValueToCompare: Comparable>(
		on value: (Element) -> ValueToCompare
	) -> [Element] {
		self.map { (value: value($0), element: $0) }
			.sorted { $0.value < $1.value }
			.map(\.element)
	}
	
	func sorted<Value1ToCompare: Comparable, Value2ToCompare: Comparable>(
		on value1: (Element) -> Value1ToCompare,
		then value2: (Element) -> Value2ToCompare
	) -> [Element] {
		self.map { (value1: value1($0), value2: value2($0), element: $0) }
			.sorted { ($0.value1, $0.value2) < ($1.value1, $1.value2) }
			.map(\.element)
	}
	
	func movingToFront(where predicate: (Element) -> Bool) -> [Element] {
		Array(self) <- { _ = $0.stablePartition { !predicate($0) } }
	}
	
	func count(where isCounted: (Element) throws -> Bool) rethrows -> Int {
		try self
			.lazy
			.filter(isCounted)
			.reduce(0) { count, _ in count + 1 }
	}
}

extension Collection {
	func elementIfValid(at index: Index) -> Element? {
		indices.contains(index) ? self[index] : nil
	}
	
	func onlyElement() -> Element? {
		count == 1 ? first! : nil
	}
}

extension Sequence {
	func onlyElement(where isIncluded: (Element) throws -> Bool) rethrows -> Element? {
		try lazy.filter(isIncluded).onlyElement()
	}
	
	func onlyElement() -> Element? {
		Array(prefix(2)).onlyElement()
	}
}

extension Collection where Element: Identifiable {
	func firstIndex(withID id: Element.ID) -> Index? {
		firstIndex { $0.id == id }
	}
}

extension Sequence where Element: Identifiable {
	func firstElement(withID id: Element.ID) -> Element? {
		first { $0.id == id }
	}
}

extension Collection where Element: RandomAccessCollection {
	func transposed() -> [[Element.Element]] {
		guard let firstRow = first else { return [] }
		return firstRow.indices.map { index in
			self.map{ $0[index] }
		}
	}
	
	func flatTransposed() -> [Element.Element] {
		guard let firstRow = first else { return [] }
		return firstRow.indices.flatMap { index in
			self.lazy.map{ $0[index] }
		}
	}
}

extension Dictionary {
	init(values: [Value], keyedBy key: (Value) -> Key) {
		self.init(uniqueKeysWithValues: values.map { (key($0), $0) })
	}
	
	init(values: [Value]) where Value: Identifiable, Key == Value.ID {
		self.init(values: values, keyedBy: \.id)
	}
}

extension Task where Success == Never, Failure == Never {
	/// The built-in ``sleep(_:)`` didn't work for me, so I made this instead.
	static func sleep(seconds: TimeInterval, tolerance: TimeInterval) async {
		// TODO: this should stop being necessary at some point
		//await sleep(UInt64(seconds * 1e9))
		await withCheckedContinuation { continuation in
			DispatchQueue.main.schedule(
				after: .init(.now() + seconds),
				tolerance: .init(floatLiteral: tolerance),
				options: nil,
				continuation.resume
			)
			//DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: continuation.resume)
		}
	}
}

/// like ``withCheckedThrowingContinuation``, but provides a completion handler instead that can be called multiple times
func withRobustThrowingContinuation<T>(
	function: String = #function,
	_ body: (@escaping (Result<T, Error>) -> Void) -> Void
) async throws -> T {
	try await withCheckedThrowingContinuation(function: function) { continuation in
		var hasResumed = false
		body {
			guard !hasResumed else { return }
			hasResumed = true
			continuation.resume(with: $0)
		}
	}
}

extension FormatStyle where Self == FloatingPointFormatStyle<Double>.Percent {
	public static var precisePercent: Self {
		.percent.precision(.fractionLength(1...1))
	}
}

extension Comparable {
	func clamped(to range: ClosedRange<Self>) -> Self {
		min(range.upperBound, max(range.lowerBound, self))
	}
}

extension Dictionary {
	subscript(ifSome key: Key?) -> Value? {
		key.flatMap { self[$0] }
	}
}
