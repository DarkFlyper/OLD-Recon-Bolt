import Algorithms
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
	
	func movingToFront(where predicate: (Element) -> Bool) -> [Element] {
		Array(self) <- { _ = $0.stablePartition { !predicate($0) } }
	}
}

extension Collection where Element: RandomAccessCollection {
	func transposed() -> [[Element.Element]] {
		guard let firstRow = first else { return [] }
		return firstRow.indices.map { index in
			self.map{ $0[index] }
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
