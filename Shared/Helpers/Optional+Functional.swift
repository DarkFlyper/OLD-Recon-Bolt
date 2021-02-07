extension Optional {
	func filter(_ predicate: (Wrapped) throws -> Bool) rethrows -> Self {
		try flatMap { try predicate($0) ? $0 : nil }
	}
}
