import Foundation
import HandyOperators

extension String {
	/// Parses as a format string Valorant uses and inserts the given number for the placeholders `Num`.
	func valorantLocalized(number: Int) -> String {
		valorantLocalized(args: ["Num": number])
	}
	
	/// Parses as a format string Valorant uses and inserts the given arguments for their placeholders.
	func valorantLocalized(args: [String: Int]) -> String {
		"" <- { output in
			var parser = Parser(reading: self)
			
			while let literalPart = parser.consume(through: "{") {
				output += literalPart
				
				let placeholderName = String(parser.consume(through: "}")!)
				guard let arg = args[placeholderName] else {
					fatalError("No format argument found for placeholder \(placeholderName) in string '\(self)'!")
				}
				
				if parser.tryConsume("|plural(one=") {
					let singular = parser.consume(through: ",")!
					parser.consume("other=")
					let plural = parser.consume(through: ")")!
					output += arg == 1 ? singular : plural
				} else {
					output += String(arg)
				}
			}
			
			output += parser.consumeRest() // no more args in the rest
		}
	}
}

private struct Parser {
	var input: Substring
	
	var isDone: Bool { input.isEmpty }
	
	var next: Character? {
		input.first
	}
	
	init<S>(reading string: S) where S: StringProtocol {
		input = Substring(string)
	}
	
	mutating func tryConsume<S>(_ part: S) -> Bool where S: StringProtocol {
		if input.hasPrefix(part) {
			input.removeFirst(part.count)
			return true
		} else {
			return false
		}
	}
	
	mutating func consume<S>(_ part: S) where S: StringProtocol {
		let wasConsumed = tryConsume(part)
		precondition(wasConsumed)
	}
	
	/// - returns: the consumed part, excluding the separator, or `nil` if the separator was not encountered
	@discardableResult
	mutating func consume(through separator: Character) -> Substring? {
		guard let index = input.firstIndex(of: separator) else { return nil }
		defer { input = input[index...].dropFirst() }
		return input.prefix(upTo: index)
	}
	
	mutating func consumeRest() -> Substring {
		defer { input = Substring() }
		return input
	}
}
