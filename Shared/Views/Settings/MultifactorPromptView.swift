import SwiftUI
import ValorantAPI

struct MultifactorPromptView: View {
	let prompt: MultifactorPrompt
	var didSessionExpire = false
	
	@State var digits: [Int] = []
	
	@Environment(\.dismiss) private var dismiss
	
	var body: some View {
		VStack {
			VStack {
				Text("2-Factor Authentication")
					.font(.title2.weight(.semibold))
				
				HStack {
					ForEach(0..<prompt.info.codeLength, id: \.self) { i in
						let size = 30.0
						Text(digits.elementIfValid(at: i).map(String.init) ?? "_")
							.font(.system(size: size))
							.frame(width: size, height: size)
							.padding(8)
							.opacity(digits.indices.contains(i) ? 1 : 0.5)
							.background(Color.secondaryGroupedBackground)
							.cornerRadius(8)
					}
				}
				.overlay {
					CodeEntry(digits: $digits)
				}
				.onChange(of: digits) {
					if $0.count == prompt.info.codeLength {
						submit()
					}
				}
			}
			.padding(.vertical)
			
			if didSessionExpire {
				Text("Your session has expired! Recon Bolt has tried to refresh it for you, but needs 2FA confirmation.")
					.frame(maxWidth: .infinity, alignment: .leading)
				Color.clear.frame(height: 0)
			}
			
			Text("A 2FA code has been sent to your email address \(prompt.info.email)")
				.frame(maxWidth: .infinity, alignment: .leading)
		}
		.padding()
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.background(Color.groupedBackground)
		.navigationTitle("Enter 2FA Code")
		.navigationBarTitleDisplayMode(.inline)
		.toolbar {
			ToolbarItemGroup(placement: .cancellationAction) {
				Button { dismiss() } label: {
					Text("Cancel")
				}
			}
		}
		.withToolbar(allowLargeTitles: false)
	}
	
	func submit() {
		let code = digits.map(String.init).joined()
		prompt.completion(.success(code))
	}
}

struct CodeEntry: UIViewRepresentable {
	@Binding var digits: [Int]
	
	func makeUIView(context: Context) -> UIViewType {
		.init(digits: $digits)
	}
	
	func updateUIView(_ uiView: UIViewType, context: Context) {}
	
	final class UIViewType: UIView, UIKeyInput, UITextInputTraits {
		@Binding var digits: [Int]
		
		var hasText: Bool { !digits.isEmpty }
		
		var keyboardType = UIKeyboardType.numberPad // has to be mutable to satisfy protocol requirement
		
		init(digits: Binding<[Int]>) {
			self._digits = digits
			super.init(frame: .null)
			
			isUserInteractionEnabled = true
			addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(becomeFirstResponder)))
		}
		
		required init?(coder: NSCoder) {
			fatalError()
		}
		
		override func didMoveToWindow() {
			super.didMoveToWindow()
			becomeFirstResponder()
		}
		
		override var canBecomeFirstResponder: Bool { true }
		override var canBecomeFocused: Bool { true }
		
		func insertText(_ text: String) {
			digits += text.compactMap { Int(String($0)) }
		}
		
		func deleteBackward() {
			guard !digits.isEmpty else { return }
			digits.removeLast()
		}
	}
}

#if DEBUG
struct MultifactorPromptView_Previews: PreviewProvider {
	static var previews: some View {
		MultifactorPromptView(
			prompt: .init(
				info: .mocked(codeLength: 6, email: "jul***@***.com"),
				completion: { _ in }
			),
			didSessionExpire: true,
			digits: [4, 2, 0]
		)
	}
}
#endif
