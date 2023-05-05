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
					output += "<\(placeholderName)>"
					continue
				}
				
				if parser.tryConsume("|plural(") {
					var forms: [String: String] = [:]
					while true {
						guard
							let category = parser.consume(through: "="),
							let (form, separator) = parser.consume(through: [",", ")"])
						else { break } // just fail and output the remaining raw string
						forms[String(category)] = String(form)
						guard separator == "," else { break } // done
					}
					
					func form(_ category: String) -> String {
						forms[category] ?? forms["other"] ?? "<???>"
					}
					output += arg == 0 ? form("zero")
					: arg == 1 ? form("one")
					: arg == 2 ? form("two")
					: form("other") // few/many rules vary between e.g. arabic and polish, so we can't support them without much more effort, and riot doesn't seem to care much either.
				} else {
					output += arg.formatted()
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
	
	/// consumes through the first separator in the set that's encountered
	@discardableResult
	mutating func consume(through separators: Set<Character>) -> (Substring, Character)? {
		guard let index = input.firstIndex(where: separators.contains(_:)) else { return nil }
		defer { input = input[index...].dropFirst() }
		return (input.prefix(upTo: index), input[index])
	}
	
	mutating func consumeRest() -> Substring {
		defer { input = Substring() }
		return input
	}
}
