import Foundation

struct Entry: TextOutputStreamable {
	var key: String
	var value: String
	var comment: String
	
	func write(to target: inout some TextOutputStream) {
		assert(!comment.contains("*/"))
		print("/* \(comment) */", to: &target)
		
		let key = key.replacingOccurrences(of: #"""#, with: #"\""#)
		let value = value.replacingOccurrences(of: #"""#, with: #"\""#)
		print(#""\#(key)" = "\#(value)";"#, to: &target)
		
		print(to: &target)
	}
}

struct File {
	var path: String
	var entries: [Entry] = []
}

// jesus this objc-era interface is annoying
final class Reader: NSObject, XMLParserDelegate {
	var files: [File] = []
	private var currentFile: File?
	private var currentUnit: Unit?
	private var currentElement: EntryElement?
	private var depth = 0
	
	private var indent: String {
		String(repeatElement("\t", count: depth))
	}
	
	func parser(_ parser: XMLParser, didStartElement element: String, namespaceURI: String?, qualifiedName: String?, attributes: [String: String]) {
		//print(indent, "started", element)
		depth += 1
		switch element {
		case "file":
			currentFile = .init(path: attributes["original"]!)
		case "trans-unit": // trans rights!
			currentUnit = .init(id: attributes["id"]!)
		default:
			if let entryElement = EntryElement(rawValue: element) {
				currentElement = entryElement
			}
			break
		}
	}
	
	func parser(_ parser: XMLParser, didEndElement element: String, namespaceURI: String?, qualifiedName: String?) {
		depth -= 1
		//print(indent, "ended", element)
		switch element {
		case "file":
			files.append(currentFile!)
			currentFile = nil
		case "trans-unit":
			let unit = currentUnit!
			currentUnit = nil
			guard let source = unit.elements[.source] else { break } // don't care about empty strings
			currentFile!.entries.append(.init(
				key: unit.id,
				value: source,
				comment: unit.elements[.note] ?? "No comment provided by engineer."
			))
		default:
			if let _ = EntryElement(rawValue: element) {
				currentElement = nil
			}
			break
		}
	}
	
	func parser(_ parser: XMLParser, foundCharacters string: String) {
		guard let element = currentElement else { return }
		currentUnit!.elements[element, default: ""] += string
		//print(indent, "|", string)
	}
	
	struct Unit {
		var id: String
		var elements: [EntryElement: String] = [:]
	}
	
	enum EntryElement: String {
		case source, note
	}
}

let projectFolder = URL(filePath: #filePath) // this source file
	.deletingLastPathComponent() // XLIFF Extractor
	.deletingLastPathComponent() // Recon Bolt

let localizationsFolder = projectFolder.appending(path: "Resources/Recon Bolt Localizations/")
let xliff = localizationsFolder.appending(path: "en.xcloc/Localized Contents/en.xliff")
print("Reading from \(xliff.relativePath)")

let reader = Reader()
let data = try! Data(contentsOf: xliff)
let parser = XMLParser(data: data)
parser.delegate = reader

guard parser.parse() else {
	print("parsing failed!")
	dump(parser.parserError)
	fatalError()
}

let outputFolder = projectFolder.appending(path: "Resources/Strings/")
print("outputting extracted files to \(outputFolder.relativePath)")

let fileManager = FileManager.default
if fileManager.fileExists(atPath: outputFolder.relativePath) {
	try! fileManager.removeItem(at: outputFolder)
}

let xliffExtensions: Set = ["strings", "intentdefinition"] // not stringsdict

func outputURL(for path: String) -> URL {
	let url = URL(filePath: path, relativeTo: outputFolder)
	try! fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
	return url
}

for file in reader.files {
	var path = file.path
	path.replace(#/(en|Base).lproj//#) { _ in "" }
	let match = path.wholeMatch(of: #/.*\.(\w+)/#)!
	let fileExtension = String(match.output.1)
	
	let importFromXLIFF = xliffExtensions.contains(fileExtension)
	if importFromXLIFF {
		// replace extension
		path.removeLast(fileExtension.count)
		path.append("strings")
		print("file \(file.path) has \(file.entries.count) entries")
		
		var fileContents = ""
		for entry in file.entries {
			entry.write(to: &fileContents)
		}
		let data = fileContents.data(using: .utf8)!
		
		print(path)
		try! data.write(to: outputURL(for: path))
	} else {
		print("file \(file.path) is not a strings file; copying from project")
		
		let sourceURL = URL(filePath: file.path, relativeTo: projectFolder)
		print(file.path)
		try! fileManager.copyItem(at: sourceURL, to: outputURL(for: path))
	}
}
