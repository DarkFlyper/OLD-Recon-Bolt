import SwiftUI

struct LabeledRow: View {
	var label: Text
	var value: Text
	
	init(_ label: LocalizedStringKey, describing value: Any) {
		self.init(Text(label), describing: value)
	}
	
	init(_ label: Text, describing value: Any) {
		self.init(label, value: Text(String(describing: value)))
	}
	
	init(_ label: LocalizedStringKey, value: LocalizedStringKey) {
		self.init(label, value: Text(value))
	}
	
	init(_ label: LocalizedStringKey, value: Text) {
		self.init(Text(label), value: value)
	}
	
	init(_ label: Text, value: Text) {
		self.label = label
		self.value = value
	}
	
	var body: some View {
		HStack {
			label
				.foregroundStyle(.secondary)
			Spacer()
			value
				.multilineTextAlignment(.trailing)
		}
	}
}

#if DEBUG
struct LabeledRow_Previews: PreviewProvider {
    static var previews: some View {
		List {
			LabeledRow(Text(verbatim: "π"), describing: Double.pi)
			LabeledRow(Text(verbatim: "π"), value: Text("\(Double.pi)"))
			LabeledRow(Text(verbatim: "π"), value: Text(Double.pi, format: .number))
			LabeledRow(Text(verbatim: "A long label because why not"), value: Text(verbatim: "some value with a really long description that requires multiple lines yes"))
		}
    }
}
#endif
