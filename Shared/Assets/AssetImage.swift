import Foundation
import SwiftUI
import Protoquest
import HandyOperators

struct AssetImage: Hashable {
	var url: URL
	
	@ViewBuilder
	func view(renderingMode: Image.TemplateRenderingMode? = nil) -> some View {
		let view = ImageView(image: self, renderingMode: renderingMode)
		if isInSwiftUIPreview {
			view.environmentObject(ImageManager())
		} else {
			view
		}
	}
	
	var localURL: URL {
		Self.localFolder.appendingPathComponent(url.path, isDirectory: false)
	}
	
	private static let localFolder = try! FileManager.default
		.url(
			for: .applicationSupportDirectory,
			in: .userDomainMask,
			appropriateFor: nil,
			create: true
		)
		.appendingPathComponent("AssetImage", isDirectory: true)
	
	static func removeCachedFiles() throws {
		try FileManager.default.removeItem(at: localFolder)
	}
	
	struct ImageView: View {
		var image: AssetImage
		var renderingMode: Image.TemplateRenderingMode? = nil
		@State private var isShowingErrorAlert = false
		@State private var loadError: Error?
		
		@EnvironmentObject private var manager: ImageManager
		
		var body: some View {
			switch manager.state(for: image) {
			case nil:
				placeholder
					.task { await manager.download(image) }
			case .downloading:
				placeholder
					.overlay { ProgressView() }
			case .errored(let error):
				placeholder
					.overlay { Image(systemName: "xmark.octagon.fill") }
					.onTapGesture {
						loadError = error
						isShowingErrorAlert = true
					}
					.alert(
						"Image failed to load!",
						isPresented: $isShowingErrorAlert,
						presenting: loadError
					) { error in
						Button("Copy Error Details") {
							UIPasteboard.general.string = error.localizedDescription
						}
						Button("OK") {}
					}
					.task { await manager.download(image) }
			case .available(let image):
				image
					.renderingMode(renderingMode)
					.resizable()
					.scaledToFit()
			}
		}
		
		var placeholder: some View {
			Color.primary.opacity(0.2)
		}
	}
}

extension Optional where Wrapped == AssetImage {
	@ViewBuilder
	func view() -> some View {
		if let self {
			self.view()
		} else {
			Color.gray
		}
	}
}

extension AssetClient {
	func download(_ image: AssetImage) async throws {
		// don't download images that we already have (assuming size will always change when the image changes)
		if let existingSize = FileManager.default.sizeOfItem(atPath: image.localURL.path) {
			print("\(image.url) found existing size \(existingSize)")
			let newSize = try await send(ImageSizeRequest(imageURL: image.url))
			guard newSize != existingSize else { return }
		} else {
			assert(!FileManager.default.fileExists(atPath: image.localURL.path))
		}
		
		let imageData = try await send(ImageDownloadRequest(imageURL: image.url))
		try FileManager.default.createDirectory(
			at: image.localURL.deletingLastPathComponent(),
			withIntermediateDirectories: true
		)
		try imageData.write(to: image.localURL)
	}
}

extension FileManager {
	func sizeOfItem(atPath path: String) -> Int? {
		guard let size = try? attributesOfItem(atPath: path)[.size] else { return nil }
		return (size as! NSNumber).intValue
	}
}

private struct ImageDownloadRequest: GetDataRequest {
	var imageURL: URL
	
	var baseURLOverride: URL? {
		imageURL
	}
}

// TODO: use a hash instead
private struct ImageSizeRequest: GetRequest {
	var imageURL: URL
	
	var baseURLOverride: URL? {
		imageURL
	}
	
	var httpMethod: String { "HEAD" }
	
	func decodeResponse(from raw: Protoresponse) throws -> Int {
		.init(raw.httpMetadata!.expectedContentLength)
	}
}

extension AssetImage: Codable {
	init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		url = try container.decode(URL.self)
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(url)
	}
}
